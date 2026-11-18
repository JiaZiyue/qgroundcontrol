pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.AutoPilotPlugins.PX4
import QGroundControl.Controls
import QGroundControl.FlightMap
import QtCore
import QtLocation

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool embedded: false

    readonly property var _battery: _vehicle && _vehicle.batteries.count > 0 ? _vehicle.batteries.get(0) : null
    readonly property bool _connected: _vehicle && !_vehicle.vehicleLinkManager.communicationLost
    property int _editingSlot: 0
    readonly property var _factLabels: ({
        "altitudeRelative": qsTr("相对高度"),
        "climbRate": qsTr("升降速度"),
        "groundSpeed": qsTr("地速"),
        "imuTemp": qsTr("惯性传感器温度"),
        "roll": qsTr("横滚角"),
        "pitch": qsTr("俯仰角"),
        "heading": qsTr("航向角"),
        "flightDistance": qsTr("飞行距离"),
        "airSpeed": qsTr("空速"),
        "altitudeAMSL": qsTr("海拔高度"),
        "throttlePct": qsTr("油门百分比"),
        "rcRSSI": qsTr("遥控信号强度"),
        "rollRate": qsTr("横滚角速度"),
        "pitchRate": qsTr("俯仰角速度"),
        "yawRate": qsTr("偏航角速度"),
        "distanceToHome": qsTr("距返航点距离"),
        "rangeFinderDist": qsTr("测距距离"),
        "gps.count": qsTr("卫星数量"),
        "gps.lock": qsTr("定位状态"),
        "gps.hdop": qsTr("水平精度因子")
    })
    property var _motorValues: []
    readonly property var _quickOptions: ["altitudeRelative", "climbRate", "groundSpeed", "imuTemp", "roll", "pitch", "heading", "flightDistance", "airSpeed", "altitudeAMSL", "throttlePct", "rcRSSI", "rollRate", "pitchRate", "yawRate", "distanceToHome", "rangeFinderDist"]
    property var _rcValues: []
    property int _sensorIndex: 0
    readonly property var _sensors: [
        {
            title: qsTr("惯性传感器（IMU）"),
            mask: 3,
            facts: ["roll", "pitch", "imuTemp"]
        },
        {
            title: qsTr("罗盘"),
            mask: 4,
            facts: ["heading"]
        },
        {
            title: qsTr("气压计"),
            mask: 8,
            facts: ["altitudeAMSL", "altitudeRelative"]
        },
        {
            title: qsTr("卫星定位（GPS）"),
            mask: 32,
            facts: ["gps.count", "gps.lock", "gps.hdop"]
        },
        {
            title: qsTr("光流"),
            mask: 64,
            facts: []
        },
        {
            title: qsTr("测距传感器"),
            mask: 256,
            facts: ["rangeFinderDist"]
        }
    ]
    readonly property real _unit: ScreenTools.defaultFontPixelHeight
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _wide: width > _unit * 65

    signal componentRequested(int component)
    signal planRequested()
    signal flyRequested
    signal setupRequested
    signal toolsRequested

    function displayValue(valueFact) {
        return _connected && valueFact && !isNaN(Number(valueFact.rawValue)) ? valueFact.valueString + " " + valueFact.units : "—";
    }

    function fact(path) {
        if (!_vehicle) {
            return null;
        }
        const parts = path.split(".");
        const group = parts.length > 1 ? _vehicle[parts[0]] : _vehicle;
        const name = parts[parts.length - 1];
        return group && group[name] ? group[name] : null;
    }

    function sensorStatus(sensor) {
        if (!_connected) {
            return qsTr("未连接");
        }
        if ((_vehicle.sensorsPresentBits & sensor.mask) !== sensor.mask) {
            return qsTr("未检测到");
        }
        if ((_vehicle.sensorsEnabledBits & sensor.mask) !== sensor.mask) {
            return qsTr("未启用");
        }
        return (_vehicle.sensorsHealthBits & sensor.mask) === sensor.mask ? qsTr("正常") : qsTr("需要检查");
    }

    color: qgcPal.window

    on_ConnectedChanged: {
        if (!_connected) {
            _rcValues = [];
            _motorValues = [];
        }
    }
    on_VehicleChanged: {
        _rcValues = [];
        _motorValues = [];
        sensorDialog.close();
    }

    Settings {
        id: settings

        property bool showMap: false

        property var quickFacts: ["altitudeRelative", "climbRate", "groundSpeed", "imuTemp", "roll", "pitch", "heading", "flightDistance"]

        category: "Dashboard"
    }

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            visible: !root.embedded
            color: qgcPal.toolbarBackground
            implicitHeight: navigation.implicitHeight + root._unit

            RowLayout {
                id: navigation

                anchors.fill: parent
                anchors.margins: root._unit / 2

                QGCButton {
                    objectName: "toolbar_qgcLogo"
                    text: qsTr("QGroundControl · 仪表盘")

                    onClicked: root.toolsRequested()
                }

                Item {
                    Layout.fillWidth: true
                }

                QGCLabel {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root._connected ? qsTr("飞机 %1 · %2").arg(root._vehicle.id).arg(root._vehicle.firmwareTypeString) : qsTr("请连接飞机以查看实时遥测数据")
                }

                QGCButton {
                    text: qsTr("飞行")

                    onClicked: root.flyRequested()
                }

                QGCButton {
                    text: qsTr("设置")

                    onClicked: root.setupRequested()
                }
            }
        }

        ScrollView {
            id: dashboardScroll

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            contentWidth: availableWidth

            Flickable {
                contentHeight: dashboardContent.implicitHeight
                contentWidth: width
                objectName: "dashboard_scroll"

                ColumnLayout {
                    id: dashboardContent

                    spacing: root._unit * 0.75
                    width: parent.width

                    Card {
                        visible: !root.embedded
                        Layout.fillWidth: true
                        Layout.margins: root._unit * 0.5

                        Flow {
                            Layout.fillWidth: true
                            spacing: root._unit

                            QGCLabel {
                                font.bold: true
                                text: !root._connected ? qsTr("未连接") : root._vehicle.armed ? qsTr("已解锁") : qsTr("未解锁")
                            }

                            QGCLabel {
                                text: qsTr("飞行模式：%1").arg(root._connected ? root._vehicle.flightMode : "—")
                            }

                            QGCLabel {
                                text: qsTr("电池电量：%1 · %2").arg(root.displayValue(root._battery ? root._battery.percentRemaining : null)).arg(root.displayValue(root._battery ? root._battery.voltage : null))
                            }

                            QGCLabel {
                                text: qsTr("定位卫星数：%1").arg(root.displayValue(root.fact("gps.count")))
                            }

                            QGCLabel {
                                color: root._connected && root._vehicle.readiness.canArm ? qgcPal.successText : qgcPal.warningText
                                text: !root._connected ? qsTr("解锁状态未知") : root._vehicle.armed ? qsTr("飞机已解锁") : root._vehicle.readiness.canArm ? qsTr("可以解锁") : qsTr("暂不能解锁")
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            color: qgcPal.warningText
                            text: root._vehicle ? root._vehicle.prearmError : ""
                            visible: root._connected && text !== ""
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            QGCButton {
                                text: qsTr("设置引导")

                                onClicked: root.setupRequested()
                            }

                            QGCButton {
                                enabled: root._connected
                                text: qsTr("解锁检查")

                                onClicked: root.componentRequested(AutoPilotPlugin.KnownSafetyVehicleComponent)
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.margins: root._unit * 0.5
                        columnSpacing: root._unit
                        columns: root._wide ? 3 : 1
                        rowSpacing: root._unit

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._unit * 21

                            QGCLabel {
                                font.bold: true
                                text: qsTr("飞机姿态")
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Loader {
                                    active: root.GraphicsInfo.api !== GraphicsInfo.Software && root.GraphicsInfo.api !== GraphicsInfo.Unknown
                                    anchors.fill: parent

                                    sourceComponent: Component {
                                        SensorsVehicleView {
                                            heading: root._connected ? root._vehicle.heading.rawValue : 0
                                            live: true
                                            pitch: root._connected ? root._vehicle.pitch.rawValue : 0
                                            roll: root._connected ? root._vehicle.roll.rawValue : 0
                                            vehicleKind: root._vehicle ? (root._vehicle.multiRotor ? "multiRotor" : root._vehicle.vtol ? "vtol" : root._vehicle.fixedWing ? "fixedWing" : root._vehicle.rover ? "rover" : "") : ""
                                        }
                                    }
                                }

                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: qsTr("三维姿态显示需要图形加速支持")
                                    visible: root.GraphicsInfo.api === GraphicsInfo.Software
                                }
                            }

                            RowLayout {
                                Repeater {
                                    model: ["roll", "pitch", "heading"]

                                    QGCLabel {
                                        required property string modelData

                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: root._factLabels[modelData] + "\n" + root.displayValue(root.fact(modelData))
                                    }
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._unit * 21

                            QGCLabel {
                                font.bold: true
                                text: qsTr("姿态仪")
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                ConfiguratorAttitude {
                                    anchors.fill: parent
                                    vehicle: root._connected ? root._vehicle : null
                                }

                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: qsTr("暂无遥测数据")
                                    visible: !root._connected
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._unit * 21

                            QGCLabel {
                                font.bold: true
                                text: qsTr("传感器")
                            }

                            GridLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                columns: 2

                                Repeater {
                                    model: root._sensors

                                    QGCButton {
                                        required property int index
                                        required property var modelData

                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        objectName: "dashboard_sensor_" + index
                                        text: modelData.title + "\n" + root.sensorStatus(modelData)

                                        onClicked: {
                                            root._sensorIndex = index;
                                            sensorDialog.open();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.margins: root._unit * 0.5
                        columnSpacing: root._unit
                        columns: root._wide ? 2 : 1
                        rowSpacing: root._unit

                        Card {
                            Layout.fillWidth: true

                            DashboardChannelMonitor {
                                Layout.fillWidth: true
                                channelPrefix: qsTr("通道")
                                connected: root._connected
                                title: qsTr("遥控器输入（微秒）")
                                values: root._rcValues
                            }
                        }

                        Card {
                            Layout.fillWidth: true

                            DashboardChannelMonitor {
                                Layout.fillWidth: true
                                channelPrefix: qsTr("输出")
                                connected: root._connected
                                title: qsTr("电机／舵机输出（微秒）")
                                values: root._motorValues
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._unit * 16

                            QGCLabel {
                                font.bold: true
                                text: qsTr("快速遥测 · 点击标签切换显示参数")
                            }

                            GridLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                columns: root._wide ? 4 : 2

                                Repeater {
                                    model: 8

                                    Rectangle {
                                        id: quickTile

                                        readonly property string factName: settings.quickFacts[index] || root._quickOptions[index]
                                        required property int index
                                        readonly property var valueFact: root.fact(factName)

                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        color: qgcPal.windowInset
                                        radius: root._unit / 2

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            width: parent.width

                                            QGCLabel {
                                                Layout.fillWidth: true
                                                color: qgcPal.accent
                                                elide: Text.ElideRight
                                                font.pointSize: ScreenTools.largeFontPointSize
                                                horizontalAlignment: Text.AlignHCenter
                                                text: root.displayValue(quickTile.valueFact)
                                            }

                                            QGCButton {
                                                Layout.fillWidth: true
                                                objectName: "dashboard_quick_" + quickTile.index
                                                text: root._factLabels[quickTile.factName] || qsTr("未知参数")

                                                onClicked: {
                                                    root._editingSlot = quickTile.index;
                                                    quickSelector.currentIndex = root._quickOptions.indexOf(quickTile.factName);
                                                    quickDialog.open();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._unit * 16

                            QGCLabel {
                                font.bold: true
                                text: qsTr("地图")
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                QGCButton {
                                    text: settings.showMap ? qsTr("位置视图") : qsTr("地图视图")
                                    onClicked: settings.showMap = !settings.showMap
                                }
                                QGCButton { text: qsTr("打开航线"); onClicked: root.planRequested() }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !settings.showMap
                                color: qgcPal.windowInset
                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: "▲"
                                    color: qgcPal.accent
                                    font.pointSize: ScreenTools.largeFontPointSize
                                    rotation: root._connected ? root._vehicle.heading.rawValue : 0
                                }
                                QGCLabel {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: root._unit / 2
                                    text: root._connected && root._vehicle.coordinate.isValid && root._vehicle.gps.lock.rawValue >= 3
                                        ? qsTr("纬度：%1°\n经度：%2°").arg(root._vehicle.coordinate.latitude.toFixed(7))
                                            .arg(root._vehicle.coordinate.longitude.toFixed(7)) : qsTr("等待有效定位…")
                                }
                            }
                            FlightMap {
                                id: map
                                visible: settings.showMap

                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                clip: true
                                mapName: "Dashboard"

                                MapQuickItem {
                                    anchorPoint.x: width / 2
                                    anchorPoint.y: height / 2
                                    coordinate: root._vehicle ? root._vehicle.coordinate : map.center
                                    visible: root._connected && root._vehicle.coordinate.isValid

                                    sourceItem: QGCLabel {
                                        color: qgcPal.accent
                                        font.pointSize: ScreenTools.largeFontPointSize
                                        rotation: root._vehicle ? root._vehicle.heading.rawValue : 0
                                        text: "▲"
                                    }
                                }

                                Column {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right

                                    QGCButton {
                                        text: "+"

                                        onClicked: map.zoomLevel += 1
                                    }

                                    QGCButton {
                                        text: "−"

                                        onClicked: map.zoomLevel -= 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: quickDialog
        objectName: "dashboard_quickDialog"

        anchors.centerIn: parent
        modal: true
        footer: DialogButtonBox {
            QGCButton {
                text: qsTr("确定")
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
            QGCButton {
                text: qsTr("取消")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            onAccepted: quickDialog.accept()
            onRejected: quickDialog.reject()
        }
        title: qsTr("选择显示参数")

        onAccepted: {
            let selected = settings.quickFacts.slice();
            selected[root._editingSlot] = root._quickOptions[quickSelector.currentIndex];
            settings.quickFacts = selected;
        }

        QGCComboBox {
            id: quickSelector

            model: root._quickOptions.map(name => root._factLabels[name])
            objectName: "dashboard_quickSelector"
            width: root._unit * 20
        }
    }

    Dialog {
        id: sensorDialog

        anchors.centerIn: parent
        modal: true
        footer: DialogButtonBox {
            QGCButton {
                text: qsTr("关闭")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            onRejected: sensorDialog.reject()
        }
        title: root._sensors[root._sensorIndex].title

        ColumnLayout {
            objectName: "dashboard_sensorDetails"
            width: Math.min(root.width * 0.8, root._unit * 28)

            QGCLabel {
                font.bold: true
                text: root.sensorStatus(root._sensors[root._sensorIndex])
            }

            Repeater {
                model: root._sensors[root._sensorIndex].facts

                QGCLabel {
                    required property string modelData
                    readonly property var valueFact: root.fact(modelData)

                    text: (root._factLabels[modelData] || qsTr("未知参数")) + "：" + root.displayValue(valueFact)
                }
            }

            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: root._sensorIndex === 4 ? root._unit * 12 : 0
                cache: false
                fillMode: Image.PreserveAspectFit
                source: root._connected && root._sensorIndex === 4 ? "image://QGCImages/" + root._vehicle.id + "/" + root._vehicle.flowImageIndex : ""
                visible: root._sensorIndex === 4 && root._connected
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("请进入传感器设置，查看配置并进行校准。")
                wrapMode: Text.WordWrap
            }

            QGCButton {
                enabled: root._connected && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
                text: qsTr("传感器设置")

                onClicked: {
                    sensorDialog.close();
                    root.componentRequested(AutoPilotPlugin.KnownSensorsVehicleComponent);
                }
            }
        }
    }

    Connections {
        function onRcChannelsRawChanged(channelValues) {
            root._rcValues = channelValues;
        }

        function onServoOutputsChanged(servoValues) {
            root._motorValues = servoValues;
        }

        target: root._vehicle
    }

    component Card: Rectangle {
        default property alias content: body.data

        border.color: qgcPal.borderSubtle
        color: qgcPal.windowCard
        implicitHeight: body.implicitHeight + root._unit * 1.5
        radius: root._unit * 0.65

        ColumnLayout {
            id: body

            anchors.fill: parent
            anchors.margins: root._unit * 0.75
            spacing: root._unit * 0.5
        }
    }
}
