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
        { key: "imu", title: qsTr("惯性传感器（IMU）") },
        { key: "compass", title: qsTr("罗盘") },
        { key: "gps", title: qsTr("卫星定位（GPS）") },
        { key: "vision", title: qsTr("外部视觉") },
        { key: "flow", title: qsTr("光流") },
        { key: "range", title: qsTr("测距仪") }
    ] : [
        {
            key: "airframe",
            title: qsTr("机架设置")
        },
        {
            key: "motors",
            title: qsTr("电机设置")
        },
        {
            key: "radio",
            title: qsTr("遥控器设置")
        },
        {
            key: "ports",
            title: qsTr("端口设置")
        },
        {
            key: "tuning",
            title: qsTr("PID 参数")
        },
        {
            key: "ekf",
            title: qsTr("EKF 状态估计")
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
        text: root.sensorMode ? qsTr("传感器") : qsTr("飞控设置")
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
        readonly property int sensorMask: ({ imu: 3, compass: 4, gps: 32, flow: 64, range: 256 })[root.selectedPage] || 0
        Layout.fillWidth: true
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        Layout.rightMargin: ScreenTools.defaultFontPixelHeight
        visible: root.sensorMode && root._vehicle && sensorMask !== 0
        wrapMode: Text.WordWrap
        text: !root._vehicle || root._vehicle.vehicleLinkManager.communicationLost ? qsTr("连接已断开，等待传感器数据。")
            : (root._vehicle.sensorsPresentBits & sensorMask) !== sensorMask ? qsTr("尚未检测到该传感器。")
            : (root._vehicle.sensorsHealthBits & sensorMask) !== sensorMask ? qsTr("传感器需要检查。") : qsTr("传感器状态正常。")
    }

    Flow {
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        visible: root.sensorMode && root._vehicle
        spacing: ScreenTools.defaultFontPixelHeight
        Repeater {
            model: !root._vehicle ? [] : root.selectedPage === "gps" ? [
                { title: qsTr("卫星数量"), valueFact: root._vehicle.gps.count },
                { title: qsTr("水平精度"), valueFact: root._vehicle.gps.horizontalAccuracy },
                { title: qsTr("垂直精度"), valueFact: root._vehicle.gps.verticalAccuracy }
            ] : root.selectedPage === "imu" ? [
                { title: qsTr("横滚角速度"), valueFact: root._vehicle.rollRate },
                { title: qsTr("俯仰角速度"), valueFact: root._vehicle.pitchRate },
                { title: qsTr("偏航角速度"), valueFact: root._vehicle.yawRate },
                { title: qsTr("惯性传感器温度"), valueFact: root._vehicle.imuTemp }
            ] : root.selectedPage === "compass" ? [
                { title: qsTr("航向"), valueFact: root._vehicle.heading }
            ] : root.selectedPage === "range" ? [
                { title: qsTr("测距距离"), valueFact: root._vehicle.rangeFinderDist }
            ] : []
            QGCLabel {
                required property var modelData
                text: modelData.title + "：" + (root._vehicle && !root._vehicle.vehicleLinkManager.communicationLost
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
        text: root._vehicle ? qsTr("正在下载飞机参数，请等待下载完成后配置。")
                            : qsTr("请先连接飞机，再选择需要配置的项目。")
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
