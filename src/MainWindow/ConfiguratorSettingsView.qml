pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls
import QGroundControl.VehicleSetup

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property QtObject navigationHost
    property bool sensorMode: false
    readonly property var pages: sensorMode ? [
        { key: "imu", title: qsTr("Inertial Measurement Unit (IMU)") },
        { key: "compass", title: qsTr("Compass") },
        { key: "gps", title: qsTr("Satellite Positioning (GPS)") },
        { key: "vision", title: qsTr("External Vision") },
        { key: "flow", title: qsTr("Optical Flow") },
        { key: "range", title: qsTr("Rangefinder") }
    ] : [
        {
            key: "airframe",
            title: qsTr("Airframe Setup")
        },
        {
            key: "motors",
            title: qsTr("Motor Setup")
        },
        {
            key: "radio",
            title: qsTr("Radio Setup")
        },
        {
            key: "ports",
            title: qsTr("Port Setup")
        },
        {
            key: "tuning",
            title: qsTr("PID Parameters")
        },
        {
            key: "ekf",
            title: qsTr("EKF State Estimation")
        }
    ]
    property string selectedPage: sensorMode ? "imu" : "airframe"
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _ready: _vehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
        && !_vehicle.parameterManager.missingParameters

    spacing: ScreenTools.defaultFontPixelHeight / 2

    QGCLabel {
        Layout.margins: ScreenTools.defaultFontPixelHeight
        font.bold: true
        font.pointSize: ScreenTools.largeFontPointSize
        text: root.sensorMode ? qsTr("Sensors") : qsTr("Flight Controller Setup")
    }

    Flow {
        Layout.fillWidth: true
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        Layout.rightMargin: ScreenTools.defaultFontPixelHeight
        spacing: ScreenTools.defaultFontPixelWidth / 2

        Repeater {
            model: root.pages

            QGCButton {
                required property var modelData

                objectName: "configurator_tab_" + modelData.key
                primary: root.selectedPage === modelData.key
                text: modelData.title

                onClicked: {
                    if (root.navigationHost.allowViewSwitch()) {
                        root.selectedPage = modelData.key;
                        configView.showConfiguratorPage(root.selectedPage);
                    }
                }
            }
        }
    }

    QGCLabel {
        readonly property int sensorMask: ({ imu: 3, compass: 4, gps: 32 })[root.selectedPage] || 0
        Layout.fillWidth: true
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        Layout.rightMargin: ScreenTools.defaultFontPixelHeight
        visible: root.sensorMode && root._vehicle && sensorMask !== 0
        wrapMode: Text.WordWrap
        text: !root._vehicle || root._vehicle.vehicleLinkManager.communicationLost ? qsTr("Connection lost. Waiting for sensor data.")
            : (root._vehicle.sensorsPresentBits & sensorMask) !== sensorMask ? qsTr("This sensor has not been detected.")
            : (root._vehicle.sensorsHealthBits & sensorMask) !== sensorMask ? qsTr("The sensor needs attention.") : qsTr("The sensor is healthy.")
    }

    Flow {
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        visible: root.sensorMode && root._vehicle
        spacing: ScreenTools.defaultFontPixelHeight
        Repeater {
            model: !root._vehicle ? [] : root.selectedPage === "gps" ? [
                { title: qsTr("Satellite Count"), valueFact: root._vehicle.gps.count },
                { title: qsTr("Horizontal Accuracy"), valueFact: root._vehicle.gps.horizontalAccuracy },
                { title: qsTr("Vertical Accuracy"), valueFact: root._vehicle.gps.verticalAccuracy }
            ] : root.selectedPage === "imu" ? [
                { title: qsTr("Roll Rate"), valueFact: root._vehicle.rollRate },
                { title: qsTr("Pitch Rate"), valueFact: root._vehicle.pitchRate },
                { title: qsTr("Yaw Rate"), valueFact: root._vehicle.yawRate },
                { title: qsTr("IMU Temperature"), valueFact: root._vehicle.imuTemp }
            ] : root.selectedPage === "compass" ? [
                { title: qsTr("Heading"), valueFact: root._vehicle.heading }
            ] : root.selectedPage === "range" ? [
                { title: qsTr("Rangefinder Distance"), valueFact: root._vehicle.rangeFinderDist }
            ] : []
            QGCLabel {
                required property var modelData
                text: qsTr("%1: %2").arg(modelData.title)
                    .arg(root._vehicle && !root._vehicle.vehicleLinkManager.communicationLost
                        && !isNaN(Number(modelData.valueFact.rawValue))
                        ? modelData.valueFact.valueString + " " + modelData.valueFact.units : "—")
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: root.sensorMode && root._vehicle && root.selectedPage !== "vision"
        visible: active
        sourceComponent: ConfiguratorSensorPlots { page: root.selectedPage; vehicle: root._vehicle }
    }

    QGCLabel {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        visible: !root._ready
        text: root._vehicle ? qsTr("Wait for vehicle parameters to finish downloading before configuring the vehicle.")
                            : qsTr("Connect a vehicle to configure its settings.")
    }
    VehicleConfigView {
        id: configView

        Layout.fillHeight: true
        Layout.fillWidth: true
        navigationVisible: false
        visible: root._ready
        objectName: "configurator_vehicleConfig"

        Component.onCompleted: showConfiguratorPage(root.selectedPage)
    }
}
