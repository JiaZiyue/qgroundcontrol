pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property int gpsIndex: 0
    property int imuIndex: 0
    required property string page
    readonly property var gps: vehicle ? (gpsIndex === 0 ? vehicle.gps : vehicle.gps2) : null

    readonly property int _autopilotComponent: inspector.autopilotComponentId(vehicle)
    readonly property bool _connected: vehicle && !vehicle.vehicleLinkManager.communicationLost
    readonly property bool _usesMessages: page === "imu" || page === "compass" || page === "flow"
    readonly property bool _canRequest: _usesMessages || page === "range"
    readonly property var _scaledImuIds: [26, 116, 129]
    readonly property int _rawImuId: 27
    readonly property int _highresImuId: 105
    readonly property int _opticalFlowId: 100
    readonly property int _opticalFlowRadId: 106
    readonly property var _system: vehicle ? findSystem(vehicle.id) : null
    readonly property var _scaledImu: findMessage(_scaledImuIds[imuIndex], _autopilotComponent)
    readonly property var _rawImu: findMessage(_rawImuId, _autopilotComponent, String(imuIndex))
    readonly property var _imuMessage: findMessage(_highresImuId, _autopilotComponent, String(imuIndex))
        || _scaledImu || _rawImu
    // ArduPilot's HIGHRES_IMU can publish incorrectly scaled magnetic readings.
    readonly property var _magMessage: vehicle && vehicle.apmFirmware ? (_scaledImu || _rawImu) : _imuMessage
    readonly property var _flowMessage: findMessage(_opticalFlowRadId, _autopilotComponent)
        || findMessage(_opticalFlowId, _autopilotComponent) || findMessage(_opticalFlowRadId) || findMessage(_opticalFlowId)
    readonly property var _targetMessage: page === "flow" ? _flowMessage
        : page === "imu" ? _imuMessage : page === "compass" ? _magMessage : null

    function requestData() {
        if (visible && _connected && _canRequest) {
            inspector.requestSensorData(vehicle, page, imuIndex)
        }
    }

    function requestMissingData() {
        const hasDistance = page === "range" && vehicle
            && isFinite(Number(vehicle.rangeFinderDist.rawValue))
        if (!_targetMessage && !hasDistance) {
            requestData()
        }
    }

    function findSystem(systemId) {
        const systems = inspector.systems
        for (let index = 0; index < systems.count; ++index) {
            const system = systems.get(index)
            if (system && system.id === systemId) {
                return system
            }
        }
        return null
    }

    function findMessage(messageId, componentId, instance) {
        if (!_system || !_connected) {
            return null
        }
        const messages = _system.messages
        for (let index = 0; index < messages.count; ++index) {
            const candidate = messages.get(index)
            if (candidate && candidate.id === messageId && candidate.recentData
                    && (componentId === undefined || candidate.compId === componentId)
                    && (instance === undefined || candidate.instanceValue === instance)) {
                return candidate
            }
        }
        return null
    }

    function selectTargetMessage() {
        const target = _targetMessage
        if (!visible || !_system || !target || target.selected) {
            return
        }

        // The inspector decodes live field values only for the selected message.
        for (let index = 0; index < _system.messages.count; ++index) {
            if (_system.messages.get(index) === target) {
                _system.selected = index
                return
            }
        }
    }

    function field(message, name) {
        for (let index = 0; index < message.fields.count; ++index) {
            const candidate = message.fields.get(index)
            if (candidate && candidate.name === name) {
                return candidate
            }
        }
        return null
    }

    function imuSeries(kind) {
        const message = kind === "mag" ? _magMessage : _imuMessage
        if (!message) {
            return []
        }

        const highResolution = message.id === _highresImuId
        // RAW_IMU has no protocol units, but ArduPilot sends the same units as SCALED_IMU.
        const useRawValues = message.id === _rawImuId && !(vehicle && vehicle.apmFirmware)
        let scale = 1
        let units = qsTr("raw")
        if (!useRawValues) {
            switch (kind) {
            case "acc":
                units = "m/s²"
                scale = highResolution ? 1 : 9.80665 / 1000
                break
            case "gyro":
                units = "°/s"
                scale = highResolution ? 180 / Math.PI : 180 / (1000 * Math.PI)
                break
            case "mag":
                units = "gauss"
                scale = highResolution ? 1 : 0.001
                break
            }
        }
        return ["x", "y", "z"].map(axis => ({
            title: axis.toUpperCase(),
            field: field(message, axis + kind),
            scale: scale,
            units: units
        }))
    }

    function flowSeries() {
        const message = _flowMessage
        if (!message) {
            return []
        }

        if (message.id === _opticalFlowRadId) {
            return [
                { title: qsTr("Optical Flow X"), field: field(message, "integrated_x"), units: "rad" },
                { title: qsTr("Optical Flow Y"), field: field(message, "integrated_y"), units: "rad" },
                { title: qsTr("Gyroscope X"), field: field(message, "integrated_xgyro"), units: "rad" },
                { title: qsTr("Gyroscope Y"), field: field(message, "integrated_ygyro"), units: "rad" }
            ]
        }

        // ArduPilot puts angular velocity in OPTICAL_FLOW's floating-point rate fields.
        const useRates = message.compId === _autopilotComponent && vehicle && vehicle.apmFirmware
        const units = useRates ? "rad/s" : "dpix"
        return [
            { title: qsTr("Optical Flow X"), field: field(message, useRates ? "flow_rate_x" : "flow_x"), units: units },
            { title: qsTr("Optical Flow Y"), field: field(message, useRates ? "flow_rate_y" : "flow_y"), units: units }
        ]
    }

    on_TargetMessageChanged: Qt.callLater(selectTargetMessage)
    onImuIndexChanged: Qt.callLater(requestMissingData)
    onPageChanged: Qt.callLater(requestMissingData)
    onVehicleChanged: Qt.callLater(requestMissingData)
    on_ConnectedChanged: Qt.callLater(requestMissingData)
    onVisibleChanged: {
        Qt.callLater(selectTargetMessage)
        Qt.callLater(requestMissingData)
    }

    Component.onCompleted: {
        Qt.callLater(selectTargetMessage)
        Qt.callLater(requestMissingData)
    }

    MAVLinkInspectorController {
        id: inspector
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.page === "gps" || root._canRequest

        QGCLabel {
            visible: root.page === "imu" || root.page === "gps"
            text: root.page === "imu" ? qsTr("Sensor Instance") : qsTr("GPS Receiver")
        }

        QGCComboBox {
            visible: root.page === "imu" || root.page === "gps"
            model: root.page === "imu" ? ["IMU 1", "IMU 2", "IMU 3"] : ["GPS 1", "GPS 2"]
            currentIndex: root.page === "imu" ? root.imuIndex : root.gpsIndex

            onActivated: {
                if (root.page === "imu") {
                    root.imuIndex = currentIndex;
                } else {
                    root.gpsIndex = currentIndex;
                }
            }
        }

        QGCButton {
            text: root.page === "imu" ? qsTr("Request IMU Data") : qsTr("Request Sensor Data")
            visible: root._canRequest
            enabled: root._connected
            onClicked: root.requestData()
        }

        QGCLabel {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: {
                if (root.page === "gps") {
                    return root.gps && root.gps.telemetryAvailable ? qsTr("Fix status: %1 · Satellites: %2")
                        .arg(root.gps.lock.enumOrValueString).arg(root.gps.count.valueString)
                        : qsTr("Waiting for GPS data.")
                }
                if (root._targetMessage) {
                    return qsTr("Receive rate: %1 Hz").arg(root._targetMessage.actualRateHz.toFixed(1))
                }
                if (root.page === "range") {
                    return root.vehicle && isFinite(Number(root.vehicle.rangeFinderDist.rawValue)) ? ""
                        : qsTr("Waiting for downward distance data (DISTANCE_SENSOR or RANGEFINDER).")
                }
                if (root.page === "flow") {
                    return qsTr("Waiting for optical flow data (OPTICAL_FLOW_RAD or OPTICAL_FLOW).")
                }
                if (root.page === "compass") {
                    return qsTr("Waiting for IMU magnetometer data.")
                }
                return qsTr("Waiting for raw IMU messages. Attitude angular rates alone do not indicate that raw IMU data has been received.")
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.page === "imu"

        ConfiguratorTelemetryPlot {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 13
            series: root.imuSeries("acc")
            objectName: "sensor_plot_acceleration"
            title: qsTr("Accelerometer")
        }

        ConfiguratorTelemetryPlot {
            objectName: "sensor_plot_gyroscope"
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 13
            series: root.imuSeries("gyro")
            title: qsTr("Gyroscope")
        }
    }

    ConfiguratorTelemetryPlot {
        objectName: "sensor_plot_magnetic_field"
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 13
        series: root.imuSeries("mag")
        title: qsTr("Live Three-Axis Magnetic Field Plot")
        visible: root.page === "compass"
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.page === "gps"

        ConfiguratorTelemetryPlot {
            objectName: "sensor_plot_satellites"
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
            series: root.gps && root.gps.telemetryAvailable ? [
                {
                    title: qsTr("Satellite Count"),
                    fact: root.gps.count
                }
            ] : []
            title: qsTr("Satellite Count History")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
            border.color: QGroundControl.globalPalette.borderSubtle
            color: QGroundControl.globalPalette.windowCard

            ConfiguratorGpsTrack {
                anchors.fill: parent
                gps: root.gps
                vehicle: root.vehicle
            }
        }
    }

    ConfiguratorTelemetryPlot {
        objectName: "sensor_plot_optical_flow"
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
        series: root.flowSeries()
        title: qsTr("Live Optical Flow Plot")
        visible: root.page === "flow"
    }

    ConfiguratorTelemetryPlot {
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
        series: root.vehicle ? [
            {
                title: qsTr("Distance"),
                fact: root.vehicle.rangeFinderDist
            }
        ] : []
        objectName: "sensor_plot_rangefinder"
        title: qsTr("Live Rangefinder Plot")
        visible: root.page === "range"
    }
}
