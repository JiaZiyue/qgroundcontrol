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
    property var _armingMessages: []
    property string _armingNotice: ""

    function rememberArmingMessage(message) {
        if (!message) return
        const messages = _armingMessages.filter(item => item !== message)
        messages.push(message)
        _armingMessages = messages.slice(-12)
        _armingNotice = message
        noticeTimer.restart()
    }

    on_VehicleChanged: {
        _armingMessages = []
        _armingNotice = ""
        noticeTimer.stop()
    }

    Timer {
        id: noticeTimer
        interval: 10000
        onTriggered: root._armingNotice = ""
    }

    Connections {
        target: root._vehicle
        function onTextMessageReceived(sysid, componentid, severity, text, description) {
            if (/pre[ -]?arm|preflight|arming|^arm[: ]|arm(ed|ing)?[ :].*(fail|denied)|解锁/i.test(text)) {
                root.rememberArmingMessage(text)
            }
        }
        function onPrearmErrorChanged(prearmError) {
            if (prearmError) root.rememberArmingMessage(prearmError)
        }
        function onArmedChanged(armed) {
            root._armingMessages = []
            root.rememberArmingMessage(armed ? qsTr("Flight controller armed") : qsTr("Flight controller disarmed"))
        }
    }


    function flightModeLabel(mode) {
        const labels = {
            "Unknown": qsTr("Unknown Mode"),
            "Manual": qsTr("Manual"),
            "Stabilized": qsTr("Stabilized"),
            "Acro": qsTr("Acro"),
            "Altitude": qsTr("Altitude"),
            "Position": qsTr("Position"),
            "Hold": qsTr("Hold"),
            "Mission": qsTr("Mission"),
            "Return": qsTr("Return"),
            "Land": qsTr("Land"),
            "Takeoff": qsTr("Takeoff"),
            "Offboard": qsTr("Offboard")
        };
        return labels[mode] || mode;
    }

    function value(fact) {
        return _connected && fact && isFinite(Number(fact.rawValue)) ? fact.valueString + " " + fact.units : "—";
    }

    color: qgcPal.windowPanel
    implicitHeight: statusFlow.implicitHeight + ScreenTools.defaultFontPixelHeight
        + (armingNotice.visible ? armingNotice.implicitHeight + ScreenTools.defaultFontPixelHeight / 2 : 0)

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
            text: !root._connected ? qsTr("Not Connected") : root._vehicle.armed ? qsTr("Armed") : qsTr("Disarmed")
            textColor: root._connected ? qgcPal.successText : qgcPal.textSecondary

            onClicked: armingDetails.open()
        }

        QGCButton {
            small: true
            enabled: root._connected && root._vehicle.flightModeSetAvailable
            text: root._connected ? root.flightModeLabel(root._vehicle.flightMode) : qsTr("Flight Mode")

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
            text: qsTr("Battery: %1 · %2").arg(root.value(root._battery ? root._battery.percentRemaining : null)).arg(root.value(root._battery ? root._battery.voltage : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("Altitude: %1").arg(root.value(root._vehicle ? root._vehicle.altitudeRelative : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("Heading: %1").arg(root.value(root._vehicle ? root._vehicle.heading : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("Satellites: %1").arg(root.value(root._vehicle ? root._vehicle.gps.count : null))
            verticalAlignment: Text.AlignVCenter
        }

        QGCLabel {
            height: armedButton.height
            text: qsTr("RC Signal: %1").arg(root._vehicle && root._vehicle.rcRSSI.rawValue >= 0 && root._vehicle.rcRSSI.rawValue <= 100 ? root.value(root._vehicle.rcRSSI) : "—")
            verticalAlignment: Text.AlignVCenter
        }

        QGCButton {
            small: true
            backRadius: ScreenTools.defaultFontPixelHeight
            text: qsTr("Setup Guide")

            onClicked: {
                setupGuide.open();
            }
        }

        QGCButton {
            small: true
            backRadius: ScreenTools.defaultFontPixelHeight
            enabled: root._connected
            text: !root._connected ? qsTr("Waiting for Connection") : root._vehicle.readiness.canArm ? qsTr("Ready to Arm") : qsTr("Arming Checks")

            onClicked: armingDetails.open()
        }
    }

    Dialog {
        id: setupGuide

        readonly property int completed: components.filter(component => component.setupComplete).length
        readonly property var components: root._vehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable ? root._vehicle.autopilotPlugin.vehicleComponents.filter(component => component.requiresSetup) : []

        anchors.centerIn: Overlay.overlay
        modal: true
        title: qsTr("Setup Guide")
        width: Math.min(ScreenTools.defaultFontPixelWidth * 60, root.width * 0.9)

        footer: DialogButtonBox {
            onRejected: setupGuide.reject()

            QGCButton {
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                text: qsTr("Close")
            }
        }

        ColumnLayout {
            width: setupGuide.availableWidth

            QGCLabel {
                Layout.fillWidth: true
                text: !root._vehicle ? qsTr("Connect a vehicle to check setup progress.") : qsTr("Completed %1 of %2 setup steps").arg(setupGuide.completed).arg(setupGuide.components.length)
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

    QGCLabel {
        id: armingNotice
        anchors.top: statusFlow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
        text: qsTr("Arming status: %1").arg(root._armingNotice)
        visible: root._armingNotice !== ""
        color: qgcPal.warningText
        wrapMode: Text.WordWrap
    }

    Dialog {
        id: armingDetails

        anchors.centerIn: Overlay.overlay
        modal: true
        title: qsTr("Arming Checks")
        width: Math.min(ScreenTools.defaultFontPixelWidth * 64, root.width * 0.85)

        footer: DialogButtonBox {
            onRejected: armingDetails.reject()

            QGCButton {
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                text: qsTr("Close")
            }
        }

        QGCLabel {
            text: (!root._vehicle || !root._connected ? qsTr("Connect a vehicle first.") : root._vehicle.prearmError !== "" ? root._vehicle.prearmError : root._vehicle.armed ? qsTr("The vehicle is armed.") : root._vehicle.readiness.canArm ? qsTr("Arming checks passed. The vehicle can be armed.") : qsTr("Arming checks have not passed. Review the vehicle messages below."))
                + (root._armingMessages.length ? "\n\n" + qsTr("Recent prearm and arming messages:") + "\n" + root._armingMessages.join("\n") : "")
            width: armingDetails.availableWidth
            wrapMode: Text.WordWrap
        }
    }
}
