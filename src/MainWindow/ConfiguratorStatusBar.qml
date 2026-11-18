pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    readonly property var _battery: _vehicle && _vehicle.batteries.count ? _vehicle.batteries.get(0) : null
    readonly property bool _connected: _vehicle && !_vehicle.vehicleLinkManager.communicationLost
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle
    required property QtObject navigationHost

    function flightModeLabel(mode) {
        const labels = {
            "Unknown": qsTr("未知模式"),
            "Manual": qsTr("手动"),
            "Stabilized": qsTr("自稳"),
            "Acro": qsTr("特技"),
            "Altitude": qsTr("定高"),
            "Position": qsTr("定点"),
            "Hold": qsTr("悬停"),
            "Mission": qsTr("任务"),
            "Return": qsTr("返航"),
            "Land": qsTr("降落"),
            "Takeoff": qsTr("起飞"),
            "Offboard": qsTr("外部控制")
        };
        return labels[mode] || mode;
    }

    function value(fact) {
        return _connected && fact && isFinite(Number(fact.rawValue)) ? fact.valueString + " " + fact.units : "—";
    }

    color: qgcPal.windowPanel
    implicitHeight: statusFlow.implicitHeight + ScreenTools.defaultFontPixelHeight

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    Flow {
        id: statusFlow

        anchors.left: parent.left
        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: ScreenTools.defaultFontPixelWidth

        QGCButton {
            id: armedButton

            backRadius: ScreenTools.defaultFontPixelHeight
            small: true
            text: !root._connected ? qsTr("未连接") : root._vehicle.armed ? qsTr("已解锁") : qsTr("未解锁")
            textColor: root._connected ? qgcPal.successText : qgcPal.textSecondary

            onClicked: armingDetails.open()
        }

        QGCButton {
            small: true
            enabled: root._connected && root._vehicle.flightModeSetAvailable
            text: root._connected ? root.flightModeLabel(root._vehicle.flightMode) : qsTr("飞行模式")

            onClicked: modeMenu.open()

            QGCMenu {
                id: modeMenu

                y: parent.height

                Repeater {
                    model: root._vehicle ? root._vehicle.flightModes : []

                    QGCMenuItem {
                        required property string modelData

                        text: root.flightModeLabel(modelData)

                        onTriggered: {
                            if (root._connected) {
                                root._vehicle.flightMode = modelData;
                            }
                        }
                    }
                }
            }
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("电池：%1 · %2").arg(root.value(root._battery ? root._battery.percentRemaining : null)).arg(root.value(root._battery ? root._battery.voltage : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("高度：%1").arg(root.value(root._vehicle ? root._vehicle.altitudeRelative : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("航向：%1").arg(root.value(root._vehicle ? root._vehicle.heading : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("卫星：%1").arg(root.value(root._vehicle ? root._vehicle.gps.count : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("遥控信号：%1").arg(root._vehicle && root._vehicle.rcRSSI.rawValue >= 0 && root._vehicle.rcRSSI.rawValue <= 100 ? root.value(root._vehicle.rcRSSI) : "—")
            verticalAlignment: Text.AlignVCenter
        }

        QGCButton {
            small: true
            backRadius: ScreenTools.defaultFontPixelHeight
            text: qsTr("设置引导")

            onClicked: {
                setupGuide.open();
            }
        }

        QGCButton {
            small: true
            backRadius: ScreenTools.defaultFontPixelHeight
            enabled: root._connected
            text: !root._connected ? qsTr("等待连接") : root._vehicle.readiness.canArm ? qsTr("可以解锁") : qsTr("解锁检查")

            onClicked: armingDetails.open()
        }
    }

    Dialog {
        id: setupGuide

        readonly property int completed: components.filter(component => component.setupComplete).length
        readonly property var components: root._vehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable ? root._vehicle.autopilotPlugin.vehicleComponents.filter(component => component.requiresSetup) : []

        anchors.centerIn: Overlay.overlay
        modal: true
        title: qsTr("设置引导")
        width: Math.min(ScreenTools.defaultFontPixelWidth * 60, root.width * 0.9)

        footer: DialogButtonBox {
            onRejected: setupGuide.reject()

            QGCButton {
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                text: qsTr("关闭")
            }
        }

        ColumnLayout {
            width: setupGuide.availableWidth

            QGCLabel {
                Layout.fillWidth: true
                text: !root._vehicle ? qsTr("请连接飞机以检查设置进度。") : qsTr("已完成 %1 / %2 项设置").arg(setupGuide.completed).arg(setupGuide.components.length)
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, setupGuide.components.length)
                value: setupGuide.completed
            }

            Repeater {
                model: setupGuide.components

                QGCButton {
                    required property var modelData

                    Layout.fillWidth: true
                    text: (modelData.setupComplete ? "✓ " : "○ ") + modelData.name

                    onClicked: {
                        if (root.navigationHost.allowViewSwitch()) {
                            setupGuide.close();
                            root.navigationHost.showVehicleComponentConfigPage(modelData);
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: armingDetails

        anchors.centerIn: Overlay.overlay
        modal: true
        title: qsTr("解锁检查")
        width: Math.min(ScreenTools.defaultFontPixelWidth * 64, root.width * 0.85)

        footer: DialogButtonBox {
            onRejected: armingDetails.reject()

            QGCButton {
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                text: qsTr("关闭")
            }
        }

        QGCLabel {
            text: !root._connected ? qsTr("请先连接飞机。") : root._vehicle.prearmError !== "" ? root._vehicle.prearmError : root._vehicle.armed ? qsTr("飞机当前已解锁。") : root._vehicle.readiness.canArm ? qsTr("当前检查通过，可以解锁。") : qsTr("尚未通过解锁检查，请检查传感器与安全配置。")
            width: armingDetails.availableWidth
            wrapMode: Text.WordWrap
        }
    }
}
