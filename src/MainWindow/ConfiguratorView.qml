pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string _lastMessage: ""
    property double _lastRateTime: Date.now()
    property int _lastReceived: 0
    property int _receiveRate: 0
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property real contentBottom: height - contentArea.y - contentArea.height
    readonly property real contentTop: contentArea.y
    property string extraPage: ""
    required property QtObject navigationHost
    property bool parametersSelected: false
    property bool sensorsSelected: false
    property bool settingsSelected: false
    readonly property real sidebarWidth: sidebar.width

    signal componentRequested(int component)
    signal flyRequested
    signal setupRequested
    signal toolsRequested

    color: qgcPal.window

    on_VehicleChanged: {
        _lastMessage = "";
        _lastReceived = _vehicle ? _vehicle.messagesReceived : 0;
        _receiveRate = 0;
        _lastRateTime = Date.now();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root._vehicle

        onTriggered: {
            const current = root._vehicle.messagesReceived;
            root._receiveRate = Math.max(0, Math.round((current - root._lastReceived) * 1000 / Math.max(1, Date.now() - root._lastRateTime)));
            root._lastRateTime = Date.now();
            root._lastReceived = current;
        }
    }

    Connections {
        function onTextMessageReceived(sysid, componentid, severity, text, description) {
            root._lastMessage = text;
        }

        target: root._vehicle
    }

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sidebar

            Layout.fillHeight: true
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9
            color: qgcPal.windowPanel

            QGCFlickable {
                id: sidebarScroll

                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth / 2
                clip: true
                contentWidth: width
                contentHeight: sidebarButtons.height

                ColumnLayout {
                    id: sidebarButtons

                    height: Math.max(implicitHeight, sidebarScroll.height)
                    spacing: ScreenTools.defaultFontPixelHeight / 4
                    width: parent.width

                    NavigationButton {
                        Layout.fillWidth: true
                        iconName: "dashboard"
                        objectName: "sidebar_dashboard"
                        primary: !root.settingsSelected && !root.sensorsSelected && !root.parametersSelected && root.extraPage === ""
                        text: qsTr("仪表盘")

                        onClicked: {
                            if (root.navigationHost.allowViewSwitch()) {
                                root.extraPage = "";
                                root.settingsSelected = false;
                                root.parametersSelected = false;
                                root.sensorsSelected = false;
                            }
                        }
                    }

                    NavigationButton {
                        Layout.fillWidth: true
                        iconName: "settings"
                        objectName: "sidebar_settings"
                        primary: root.settingsSelected
                        text: qsTr("设置")

                        onClicked: {
                            if (root.navigationHost.allowViewSwitch()) {
                                root.extraPage = "";
                                root.settingsSelected = true;
                                root.parametersSelected = false;
                                root.sensorsSelected = false;
                            }
                        }
                    }

                    NavigationButton {
                        Layout.fillWidth: true
                        iconName: "sensors"
                        objectName: "sidebar_sensors"
                        primary: root.sensorsSelected
                        text: qsTr("传感器")

                        onClicked: {
                            if (root.navigationHost.allowViewSwitch()) {
                                root.extraPage = "";
                                root.settingsSelected = false;
                                root.parametersSelected = false;
                                root.sensorsSelected = true;
                            }
                        }
                    }

                    NavigationButton {
                        Layout.fillWidth: true
                        iconName: "parameters"
                        objectName: "sidebar_parameters"
                        primary: root.parametersSelected
                        text: qsTr("参数")

                        onClicked: {
                            if (root.navigationHost.allowViewSwitch()) {
                                root.extraPage = "";
                                root.settingsSelected = false;
                                root.sensorsSelected = false;
                                root.parametersSelected = true;
                            }
                        }
                    }

                    Repeater {
                        model: [
                            {
                                key: "messages",
                                title: qsTr("消息")
                            },
                            {
                                key: "mission",
                                title: qsTr("航线")
                            },
                            {
                                key: "logs",
                                title: qsTr("日志")
                            },
                            {
                                key: "waveforms",
                                title: qsTr("波形")
                            },
                            {
                                key: "firmware",
                                title: qsTr("固件")
                            },
                            {
                                key: "hardware",
                                title: qsTr("硬件")
                            }
                        ]

                        NavigationButton {
                            required property var modelData

                            Layout.fillWidth: true
                            iconName: modelData.key
                            objectName: "sidebar_" + modelData.key
                            primary: root.extraPage === modelData.key
                            text: modelData.title

                            onClicked: {
                                if (root.navigationHost.allowViewSwitch()) {
                                    if (modelData.key === "mission") {
                                        root.navigationHost.showConfiguratorPlanView();
                                    } else {
                                        root.settingsSelected = false;
                                        root.sensorsSelected = false;
                                        root.parametersSelected = false;
                                        root.extraPage = modelData.key;
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        text: qsTr("全部工具")
                    small: true
                    leftPadding: ScreenTools.defaultFontPixelWidth / 2
                    rightPadding: leftPadding

                        onClicked: root.toolsRequested()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth

                QGCButton {
                    objectName: "toolbar_qgcLogo"
                    text: qsTr("QGroundControl 地面站")

                    onClicked: root.toolsRequested()
                }

                Item {
                    Layout.fillWidth: true
                }

                QGCButton {
                    text: qgcPal.globalTheme === QGCPalette.Light ? qsTr("深色") : qsTr("浅色")

                    onClicked: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue = qgcPal.globalTheme === QGCPalette.Light
                }

                QGCButton {
                    objectName: "configurator_reboot"
                    text: qsTr("重启飞控")
                    enabled: root._vehicle && !root._vehicle.armed
                        && !root._vehicle.vehicleLinkManager.communicationLost

                    onClicked: {
                        const vehicle = root._vehicle;
                        QGroundControl.showMessageDialog(root, qsTr("重启飞控"),
                            qsTr("确定重启当前飞控吗？重启期间连接会暂时中断。"),
                            Dialog.Cancel | Dialog.Ok, function() {
                                if (vehicle && vehicle === root._vehicle && !vehicle.armed
                                        && !vehicle.vehicleLinkManager.communicationLost) {
                                    vehicle.rebootVehicle();
                                }
                            });
                    }
                }

                ConfiguratorConnectionControl {
                    navigationHost: root.navigationHost
                }
            }

            ConfiguratorStatusBar {
                Layout.fillWidth: true
                navigationHost: root.navigationHost
            }

            Item {
                id: contentArea

                Layout.fillHeight: true
                Layout.fillWidth: true

                DashboardView {
                    anchors.fill: parent
                    embedded: true
                    visible: !root.settingsSelected && !root.sensorsSelected && !root.parametersSelected && root.extraPage === ""

                    onComponentRequested: component => root.componentRequested(component)
                    onFlyRequested: root.flyRequested()
                    onPlanRequested: {
                        if (root.navigationHost.allowViewSwitch()) {
                            root.navigationHost.showConfiguratorPlanView();
                        }
                    }
                    onSetupRequested: {
                        if (root.navigationHost.allowViewSwitch()) {
                            root.extraPage = "";
                            root.settingsSelected = true;
                            root.parametersSelected = false;
                            root.sensorsSelected = false;
                        }
                    }
                    onToolsRequested: root.toolsRequested()
                }

                Loader {
                    active: root.extraPage !== "" && root.extraPage !== "mission"
                    anchors.fill: parent

                    sourceComponent: ConfiguratorToolsView {
                        navigationHost: root.navigationHost
                        page: root.extraPage
                    }
                }

                Loader {
                    active: root.parametersSelected
                    anchors.fill: parent

                    sourceComponent: ConfiguratorParametersView {
                    }
                }

                Loader {
                    active: root.sensorsSelected
                    anchors.fill: parent

                    sourceComponent: ConfiguratorSettingsView {
                        navigationHost: root.navigationHost
                        sensorMode: true
                    }
                }

                Loader {
                    active: root.settingsSelected
                    anchors.fill: parent

                    sourceComponent: ConfiguratorSettingsView {
                        navigationHost: root.navigationHost
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root._lastMessage
                }

                QGCLabel {
                    text: root._vehicle ? qsTr("飞机 %1 · %2 · %3 msg/s").arg(root._vehicle.id).arg(root._vehicle.firmwareTypeString).arg(root._receiveRate) : qsTr("未连接")
                }
            }
        }
    }

    component NavigationButton: QGCButton {
        id: navigationButton

        required property string iconName

        Layout.minimumWidth: 0
        backgroundColor: primary ? qgcPal.accentSubtle : qgcPal.windowPanel
        implicitHeight: ScreenTools.defaultFontPixelHeight * 3
        implicitWidth: ScreenTools.defaultFontPixelWidth * 7
        leftPadding: ScreenTools.defaultFontPixelWidth / 2
        rightPadding: leftPadding
        showBorder: false

        contentItem: Column {
            spacing: ScreenTools.defaultFontPixelHeight / 5

            QGCColoredImage {
                anchors.horizontalCenter: parent.horizontalCenter
                color: navigationButton.primary ? qgcPal.accent : qgcPal.textSecondary
                height: width
                source: Qt.resolvedUrl("Images/" + navigationButton.iconName + ".svg")
                width: ScreenTools.defaultFontPixelHeight * 1.2
            }

            QGCLabel {
                color: navigationButton.primary ? qgcPal.accent : qgcPal.textSecondary
                font.pointSize: ScreenTools.smallFontPointSize
                horizontalAlignment: Text.AlignHCenter
                text: navigationButton.text
                width: parent.width
            }
        }
    }
}
