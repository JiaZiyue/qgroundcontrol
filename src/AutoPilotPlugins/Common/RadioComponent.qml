import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.VehicleSetup

SetupPage {
    id: radioPage
    pageComponent: pageComponent

    Component {
        id: pageComponent

        ColumnLayout {
            width: availableWidth
            spacing: ScreenTools.defaultFontPixelHeight
            property bool calibrating: false
            property var channelValues: []
            id: overview

            FactPanelController { id: settingsController }
            function fact(name) {
                return settingsController.parameterExists(-1, name) ? settingsController.getParameterFact(-1, name) : null
            }
            function labels(fact) {
                if (!fact) return []
                const names = {"Unassigned": "未分配", "Disabled": "禁用", "Position": "定点", "Position / Cruise": "定点／巡航", "Altitude": "定高", "Manual": "手动", "Stabilized": "自稳", "Acro": "特技", "Hold": "悬停", "Mission": "任务", "Return": "返航", "Land": "降落", "Offboard": "外部控制"}
                return fact.enumStrings.map(text => names[text] || text.replace(/^Channel /, "通道 "))
            }

            Connections {
                target: settingsController.vehicle
                function onRcChannelsRawChanged(channelValues) { overview.channelValues = channelValues }
            }

            QGCGroupBox {
                heading: qsTr("接收机设置")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    QGCLabel { text: qsTr("接收机协议") }
                    FactComboBox {
                        fact: overview.fact("RC_INPUT_PROTO")
                        visible: fact !== null
                        Layout.fillWidth: true
                        indexModel: false; model: overview.labels(fact)
                    }
                    QGCLabel { text: qsTr("协议由飞控自动检测或由接收机配置决定"); visible: !settingsController.parameterExists(-1, "RC_INPUT_PROTO") }
                    QGCLabel { text: qsTr("接收机端口") }
                    FactComboBox {
                        fact: overview.fact("RC_PORT_CONFIG")
                        visible: fact !== null
                        Layout.fillWidth: true
                        indexModel: false; model: overview.labels(fact)
                    }
                }
            }

            QGCGroupBox {
                heading: qsTr("遥控器通道")
                QGCButton {
                    text: overview.calibrating ? qsTr("收起校准面板") : qsTr("校准遥控器")
                    onClicked: overview.calibrating = !overview.calibrating
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    Repeater {
                        model: 16
                        RowLayout {
                            required property int index
                            readonly property int channel: (index % 2) * 8 + Math.floor(index / 2)
                            readonly property int value: channel < overview.channelValues.length ? overview.channelValues[channel] : -1
                            Layout.fillWidth: true
                            QGCLabel { text: qsTr("通道 %1").arg(parent.channel + 1); Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9 }
                            ProgressBar { Layout.fillWidth: true; from: 800; to: 2200; value: parent.value > 0 ? parent.value : 800 }
                            QGCLabel { text: parent.value > 0 ? parent.value : "—"; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6 }
                        }
                    }
                }
            }

            QGCPalette { id: radioPalette }

            QGCGroupBox {
                heading: qsTr("飞行模式")
                RowLayout {
                    Layout.fillWidth: true
                    QGCLabel {
                        font.bold: true
                        text: settingsController.vehicle ? settingsController.vehicle.flightMode : "—"
                        color: radioPalette.accent
                    }
                    Item { Layout.fillWidth: true }
                    QGCLabel { text: qsTr("模式通道"); font.bold: true }
                    FactComboBox {
                        objectName: "radio_modeChannel"
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
                        fact: overview.fact("RC_MAP_FLTMODE")
                        indexModel: false
                        model: overview.labels(fact)
                        enabled: fact !== null
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: width > ScreenTools.defaultFontPixelWidth * 80 ? 3 : 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 2
                    rowSpacing: ScreenTools.defaultFontPixelHeight
                    Repeater {
                        model: 6
                        Rectangle {
                            id: modeCard
                            required property int index
                            readonly property var modeFact: overview.fact("COM_FLTMODE" + (index + 1))
                            Layout.fillWidth: true
                            implicitHeight: modeContent.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                            color: radioPalette.windowCard
                            border.color: radioPalette.borderSubtle
                            radius: ScreenTools.defaultFontPixelHeight
                            visible: modeFact !== null

                            ColumnLayout {
                                id: modeContent
                                anchors.fill: parent
                                anchors.margins: ScreenTools.defaultFontPixelHeight
                                spacing: ScreenTools.defaultFontPixelHeight / 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    QGCLabel { text: qsTr("模式 %1").arg(modeCard.index + 1); font.bold: true }
                                    Item { Layout.fillWidth: true }
                                }
                                FactComboBox {
                                    objectName: "radio_modeSlot_" + (modeCard.index + 1)
                                    Layout.fillWidth: true
                                    fact: modeCard.modeFact
                                    indexModel: false
                                }
                            }
                        }
                    }
                }
            }

            QGCGroupBox {
                heading: qsTr("开关设置")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    Repeater {
                        model: [
                            {name: "RC_MAP_ARM_SW", label: qsTr("解锁开关通道")},
                            {name: "RC_MAP_GEAR_SW", label: qsTr("起落架开关通道")},
                            {name: "RC_MAP_KILL_SW", label: qsTr("紧急停机开关通道")},
                            {name: "RC_MAP_LOITER_SW", label: qsTr("悬停开关通道")},
                            {name: "RC_MAP_OFFB_SW", label: qsTr("外部控制开关通道")},
                            {name: "RC_MAP_RETURN_SW", label: qsTr("返航开关通道")}
                        ]
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            visible: settingsController.parameterExists(-1, modelData.name)
                            QGCLabel { text: parent.modelData.label; Layout.fillWidth: true }
                            FactComboBox { fact: overview.fact(parent.modelData.name); indexModel: false; model: overview.labels(fact) }
                        }
                    }
                }
            }

        RemoteControlCalibration {
            visible: overview.calibrating
            id: remoteControlCalibration

            useDeadband: false

            controller: RadioComponentController {
                statusText: remoteControlCalibration.statusText
                cancelButton: remoteControlCalibration.cancelButton
                nextButton: remoteControlCalibration.nextButton
                joystickMode: false

                onThrottleReversedCalFailure: QGroundControl.showMessageDialog(radioPage, qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
            }

            Component.onCompleted: controller.start()

            additionalSetupComponent: ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                ColumnLayout {
                    id: switchSettings
                    Layout.fillWidth: true

                    Repeater {
                        model: QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
                                    (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
                                        [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3", "RC_MAP_PAY_SW"] :
                                        [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3", "RC_MAP_PAY_SW"]) :
                                    0

                        LabelledFactComboBox {
                            label: fact.shortDescription
                            fact: remoteControlCalibration.controller.getParameterFact(-1, modelData)
                            indexModel: false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: qgcPal.textPrimary
                }

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCButton {
                        id: bindButton
                        text: qsTr("Spektrum Bind")
                        onClicked: spektrumBindDialogFactory.open()
                    }

                    QGCButton {
                        text: qsTr("CRSF Bind")
                        onClicked: QGroundControl.showMessageDialog(radioPage, qsTr("CRSF Bind"),
                                                                qsTr("Click Ok to place your CRSF receiver in the bind mode."),
                                                                Dialog.Ok | Dialog.Cancel,
                                                                function() { controller.crsfBindMode() })
                    }

                    QGCButton {
                        text: qsTr("Copy Trims")
                        onClicked: QGroundControl.showMessageDialog(radioPage, qsTr("Copy Trims"),
                                                                qsTr("Center your sticks and move throttle all the way down, then press Ok to copy trims. After pressing Ok, reset the trims on your radio back to zero."),
                                                                Dialog.Ok | Dialog.Cancel,
                                                                function() { controller.copyTrims() })
                    }
                }

                QGCPopupDialogFactory {
                    id: spektrumBindDialogFactory

                    dialogComponent: spektrumBindDialogComponent
                }

                Component {
                    id: spektrumBindDialogComponent

                    QGCPopupDialog {
                        title: qsTr("Spektrum Bind")
                        buttons: Dialog.Ok | Dialog.Cancel

                        onAccepted: { controller.spektrumBindMode(radioGroup.checkedButton.bindMode) }

                        ButtonGroup { id: radioGroup }

                        ColumnLayout {
                            spacing: ScreenTools.defaultFontPixelHeight / 2

                            QGCLabel {
                                wrapMode: Text.WordWrap
                                text: qsTr("Click Ok to place your Spektrum receiver in the bind mode.")
                            }

                            QGCLabel {
                                wrapMode: Text.WordWrap
                                text: qsTr("Select the specific receiver type below:")
                            }

                            QGCRadioButton {
                                text: qsTr("DSM2 Mode")
                                ButtonGroup.group: radioGroup
                                property int bindMode: RadioComponentController.DSM2
                            }

                            QGCRadioButton {
                                text: qsTr("DSMX (7 channels or less)")
                                ButtonGroup.group: radioGroup
                                property int bindMode: RadioComponentController.DSMX7
                            }

                            QGCRadioButton {
                                checked: true
                                text: qsTr("DSMX (8 channels or more)")
                                ButtonGroup.group: radioGroup
                                property int bindMode: RadioComponentController.DSMX8
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
