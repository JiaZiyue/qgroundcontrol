pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    readonly property var _imuNames: imuIndex === 0 ? ["HIGHRES_IMU", "SCALED_IMU", "RAW_IMU"] : imuIndex === 1 ? ["SCALED_IMU2"] : ["SCALED_IMU3"]
    readonly property var gps: vehicle ? (gpsIndex === 0 ? vehicle.gps : vehicle.gps2) : null
    property int gpsIndex: 0
    property int imuIndex: 0
    required property string page
    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle

    function requestImu() {
        if (visible && vehicle && page === "imu") inspector.requestRawImu(imuIndex)
    }
    Component.onCompleted: Qt.callLater(requestImu)
    onImuIndexChanged: Qt.callLater(requestImu)
    onVehicleChanged: Qt.callLater(requestImu)
    onVisibleChanged: Qt.callLater(requestImu)

    function field(names, fieldName) {
        const item = message(names);
        if (!item) {
            return null;
        }
        for (let index = 0; index < item.fields.count; ++index) {
            const candidate = item.fields.get(index);
            if (candidate.name === fieldName) {
                return candidate;
            }
        }
        return null;
    }

    function imuSeries(kind) {
        const item = message(_imuNames);
        const highResolution = item && item.name === "HIGHRES_IMU";
        const scale = kind === "acc" ? (highResolution ? 1 : 9.80665 / 1000) : kind === "gyro" ? (highResolution ? 180 / Math.PI : 180 / (1000 * Math.PI)) : highResolution ? 1 : 0.001;
        const units = kind === "acc" ? "m/s²" : kind === "gyro" ? "°/s" : "gauss";
        return ["x", "y", "z"].map(axis => ({
                    title: axis.toUpperCase(),
                    field: field(_imuNames, axis + kind),
                    scale: scale,
                    units: units
                }));
    }

    function message(names) {
        const system = inspector.activeSystem;
        if (!system || !vehicle || system.id !== vehicle.id) {
            return null;
        }
        for (const name of names) {
            for (let index = 0; index < system.messages.count; ++index) {
                const candidate = system.messages.get(index);
                if (candidate.name === name && candidate.compId === 1) {
                    return candidate;
                }
            }
        }
        return null;
    }

    Timer {
        interval: 250
        running: root.visible && root.vehicle
        repeat: true
        onTriggered: {
            const system = inspector.activeSystem
            const target = root.message(root.page === "flow" ? ["OPTICAL_FLOW_RAD"] : root._imuNames)
            if (!system || !target) { return }
            for (let index = 0; index < system.messages.count; ++index) {
                if (system.messages.get(index) === target && system.selected !== index) {
                    system.selected = index
                    return
                }
            }
        }
    }

    MAVLinkInspectorController {
        id: inspector
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.page === "imu" || root.page === "gps"

        QGCLabel {
            text: root.page === "imu" ? qsTr("传感器实例") : qsTr("GPS 接收机")
        }

        QGCComboBox {
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
            text: qsTr("请求 IMU 数据")
            visible: root.page === "imu"
            enabled: root.vehicle !== null
            onClicked: root.requestImu()
        }

        QGCLabel {
            Layout.fillWidth: true
            text: root.page === "gps" && root.gps ? qsTr("定位状态：%1 · 卫星数量：%2").arg(root.gps.lock.enumOrValueString).arg(root.gps.count.valueString) : root.message(root._imuNames) ? qsTr("接收频率：%1 Hz").arg(root.message(root._imuNames).actualRateHz.toFixed(1)) : qsTr("等待原始 IMU 消息；姿态角速度不代表已收到原始 IMU 数据。")
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
            title: qsTr("加速度计")
        }

        ConfiguratorTelemetryPlot {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 13
            series: root.imuSeries("gyro")
            title: qsTr("陀螺仪")
        }
    }

    ConfiguratorTelemetryPlot {
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 13
        series: root.imuSeries("mag")
        title: qsTr("磁场三轴实时波形")
        visible: root.page === "compass"
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.page === "gps"

        ConfiguratorTelemetryPlot {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
            series: root.gps ? [
                {
                    title: qsTr("卫星数量"),
                    fact: root.gps.count
                }
            ] : []
            title: qsTr("卫星数量趋势")
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
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
        series: [
            {
                title: qsTr("光流 X"),
                field: root.field(["OPTICAL_FLOW_RAD"], "integrated_x"),
                scale: 1,
                units: "rad"
            },
            {
                title: qsTr("光流 Y"),
                field: root.field(["OPTICAL_FLOW_RAD"], "integrated_y"),
                scale: 1,
                units: "rad"
            },
            {
                title: qsTr("陀螺仪 X"),
                field: root.field(["OPTICAL_FLOW_RAD"], "integrated_xgyro"),
                scale: 1,
                units: "rad"
            },
            {
                title: qsTr("陀螺仪 Y"),
                field: root.field(["OPTICAL_FLOW_RAD"], "integrated_ygyro"),
                scale: 1,
                units: "rad"
            }
        ]
        title: qsTr("光流实时波形")
        visible: root.page === "flow"
    }

    ConfiguratorTelemetryPlot {
        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
        series: root.vehicle ? [
            {
                title: qsTr("距离"),
                fact: root.vehicle.rangeFinderDist
            }
        ] : []
        title: qsTr("测距仪实时波形")
        visible: root.page === "range"
    }
}
