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
                const names = {"Unassigned": qsTr("Unassigned"), "Disabled": qsTr("Disabled"), "Position": qsTr("Position"), "Position / Cruise": qsTr("Position / Cruise"), "Altitude": qsTr("Altitude"), "Manual": qsTr("Manual"), "Stabilized": qsTr("Stabilized"), "Acro": qsTr("Acro"), "Hold": qsTr("Hold"), "Mission": qsTr("Mission"), "Return": qsTr("Return"), "Land": qsTr("Land"), "Offboard": qsTr("Offboard")}
                return fact.enumStrings.map(text => names[text] || text.replace(/^Channel (.+)$/, (_, channel) => qsTr("Channel %1").arg(channel)))
            }

            Connections {
                target: settingsController.vehicle
                function onRcChannelsRawChanged(channelValues) { overview.channelValues = channelValues }
            }

            QGCGroupBox {
                heading: qsTr("Receiver Setup")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    QGCLabel { text: qsTr("Receiver Protocol") }
                    FactComboBox {
                        fact: overview.fact("RC_INPUT_PROTO")
                        visible: fact !== null
                        Layout.fillWidth: true
                        indexModel: false; model: overview.labels(fact)
                    }
                    QGCLabel { text: qsTr("The protocol is detected by the flight controller or set by the receiver configuration."); visible: !settingsController.parameterExists(-1, "RC_INPUT_PROTO") }
                    QGCLabel { text: qsTr("Receiver Port") }
                    FactComboBox {
                        fact: overview.fact("RC_PORT_CONFIG")
                        visible: fact !== null
                        Layout.fillWidth: true
                        indexModel: false; model: overview.labels(fact)
                    }
                }
            }

            QGCGroupBox {
                heading: qsTr("RC Channels")
                QGCButton {
                    text: overview.calibrating ? qsTr("Hide Calibration Panel") : qsTr("Calibrate Radio")
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
                            QGCLabel { text: qsTr("Channel %1").arg(parent.channel + 1); Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9 }
                            ProgressBar { Layout.fillWidth: true; from: 800; to: 2200; value: parent.value > 0 ? parent.value : 800 }
                            QGCLabel { text: parent.value > 0 ? parent.value : "—"; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6 }
                        }
                    }
                }
            }

            QGCPalette { id: radioPalette }

            QGCGroupBox {
                heading: qsTr("Flight Modes")
                RowLayout {
                    Layout.fillWidth: true
                    QGCLabel {
                        font.bold: true
                        text: settingsController.vehicle ? settingsController.vehicle.flightMode : "—"
                        color: radioPalette.accent
                    }
                    Item { Layout.fillWidth: true }
                    QGCLabel { text: qsTr("Mode Channel"); font.bold: true }
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
                                    QGCLabel { text: qsTr("Mode %1").arg(modeCard.index + 1); font.bold: true }
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
                heading: qsTr("Switch Setup")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    Repeater {
                        model: [
                            {name: "RC_MAP_ARM_SW", label: qsTr("Arming Switch Channel")},
                            {name: "RC_MAP_GEAR_SW", label: qsTr("Landing Gear Switch Channel")},
                            {name: "RC_MAP_KILL_SW", label: qsTr("Kill Switch Channel")},
                            {name: "RC_MAP_LOITER_SW", label: qsTr("Hold Switch Channel")},
                            {name: "RC_MAP_OFFB_SW", label: qsTr("Offboard Switch Channel")},
                            {name: "RC_MAP_RETURN_SW", label: qsTr("Return Switch Channel")}
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
