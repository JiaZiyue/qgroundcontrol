pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.VehicleSetup

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    readonly property bool _requiresVehicle: !(page === "logs" && tab === 1)
    readonly property string _source: page === "messages" ? (tab === 1 ? "qrc:/qml/QGroundControl/AnalyzeView/MAVLinkInspector/MAVLinkInspectorPage.qml" : tab === 2 ? "qrc:/qml/QGroundControl/AnalyzeView/MAVLinkConsole/MAVLinkConsolePage.qml" : "") : page === "logs" ? (tab === 0 ? "qrc:/qml/QGroundControl/AnalyzeView/OnboardLogs/OnboardLogPage.qml" : "qrc:/qml/QGroundControl/AnalyzeView/LogViewer/LogViewerPage.qml") : page === "waveforms" && tab === 1 ? "qrc:/qml/QGroundControl/AnalyzeView/MAVLinkInspector/MAVLinkInspectorPage.qml" : ""
    readonly property var _tabs: page === "messages" ? [qsTr("Flight Messages"), qsTr("MAVLink Messages"), qsTr("System Console")] : page === "logs" ? [qsTr("Onboard Logs"), qsTr("Local Log Analysis")] : page === "waveforms" ? [qsTr("Live Plots"), qsTr("MAVLink Field Plots")] : []
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle
    required property QtObject navigationHost
    required property string page
    property int tab: 0

    spacing: ScreenTools.defaultFontPixelHeight / 2

    onPageChanged: tab = 0

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    QGCLabel {
        Layout.margins: ScreenTools.defaultFontPixelHeight
        font.bold: true
        font.pointSize: ScreenTools.largeFontPointSize
        text: ({
                messages: qsTr("Message Console"),
                logs: qsTr("Logs"),
                waveforms: qsTr("Plots"),
                firmware: qsTr("Firmware Update"),
                hardware: qsTr("Hardware Information")
            })[root.page] || ""
    }

    RowLayout {
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        visible: root._tabs.length > 0

        Repeater {
            model: root._tabs

            QGCButton {
                required property int index
                required property string modelData

                objectName: "configurator_toolTab_" + index
                primary: root.tab === index
                text: modelData

                onClicked: {
                    if (root.navigationHost.allowViewSwitch()) {
                        root.tab = index;
                    }
                }
            }
        }
    }

    QGCLabel {
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        Layout.fillWidth: true
        visible: root.page === "logs" && root.tab === 0 && !loggingOptions.active
        text: root._vehicle ? qsTr("Logging Mode: Waiting for flight controller parameters to load.") : qsTr("Logging Mode: Connect a flight controller first.")
    }

    Loader {
        id: loggingOptions

        Layout.fillWidth: true
        Layout.leftMargin: ScreenTools.defaultFontPixelHeight
        Layout.rightMargin: ScreenTools.defaultFontPixelHeight
        active: root.page === "logs" && root.tab === 0 && root._vehicle
                && (root._vehicle.parameterManager.parametersReady
                    || root._vehicle.parameterManager.parameterExists(-1, "SDLOG_MODE")
                    || root._vehicle.parameterManager.parameterExists(-1, "LOG_DISARMED"))
        visible: active
        sourceComponent: ColumnLayout {
            id: loggingSettings

            readonly property var modeFact: controller.parameterExists(-1, "SDLOG_MODE")
                ? controller.getParameterFact(-1, "SDLOG_MODE")
                : controller.parameterExists(-1, "LOG_DISARMED")
                    ? controller.getParameterFact(-1, "LOG_DISARMED") : null

            function optionLabel(value, original) {
                if (modeFact && modeFact.name === "SDLOG_MODE") {
                    const labels = {
                        "-1": qsTr("Disable logging"),
                        "0": qsTr("Log from arming to disarming"),
                        "1": qsTr("Log from startup until first disarm"),
                        "2": qsTr("Log from startup to shutdown"),
                        "3": qsTr("Log when RC AUX1 input exceeds 30%"),
                        "4": qsTr("Log from first arming to shutdown")
                    };
                    return labels[String(value)] || original;
                }
                if (Number(value) === 0) {
                    return qsTr("Log only while armed");
                }
                if (Number(value) === 1) {
                    return qsTr("Log while disarmed as well");
                }
                return original;
            }

            FactPanelController {
                id: controller
            }

            RowLayout {
                Layout.fillWidth: true

                QGCLabel {
                    text: qsTr("Logging Mode")
                    font.bold: true
                }

                FactComboBox {
                    objectName: "configurator_logMode"
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 48
                    fact: loggingSettings.modeFact
                    indexModel: false
                    model: fact ? fact.enumValues.map((value, index) => loggingSettings.optionLabel(value, fact.enumStrings[index])) : []
                    enabled: root._vehicle && !root._vehicle.armed && fact && fact.enumValues.length > 0
                    visible: loggingSettings.modeFact !== null
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: loggingSettings.modeFact ? loggingSettings.modeFact.name : qsTr("The current flight controller has no logging mode parameter")
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: !loggingSettings.modeFact ? "" : root._vehicle && root._vehicle.armed
                    ? qsTr("Disarm before changing the logging mode.")
                    : loggingSettings.modeFact.vehicleRebootRequired
                        ? qsTr("Changes are saved to the flight controller and take effect after it restarts. This setting controls onboard logging. Logging also depends on the logging backend and storage status.")
                        : qsTr("Changes are saved to the flight controller. Logging also depends on the logging backend and storage status.")
            }
        }
    }

    QGCLabel {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("Connect a vehicle first.")
        verticalAlignment: Text.AlignVCenter
        visible: !root._vehicle && root._requiresVehicle && root.page !== "firmware"
    }

    QGCFlickable {
        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true
        contentHeight: messageText.implicitHeight
        visible: root.page === "messages" && root.tab === 0 && root._vehicle

        QGCLabel {
            id: messageText

            text: root._vehicle ? root._vehicle.formattedMessages : ""
            textFormat: Text.RichText
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    Loader {
        Layout.fillHeight: true
        Layout.fillWidth: true
        active: root._source !== "" && (!root._requiresVehicle || root._vehicle)
        source: active ? root._source : ""
        visible: active

        onLoaded: {
            if (item && root.page === "logs" && root.tab === 0) {
                item.sortByLogId();
            }
            if (item) {
                item.objectName = "configurator_toolContent";
            }
            if (item && item.allowPopout !== undefined) {
                item.allowPopout = false;
            }
        }
    }

    Loader {
        Layout.fillHeight: true
        Layout.fillWidth: true
        active: root.page === "firmware"
        visible: active

        sourceComponent: FirmwareUpgrade {
            property var vehicleComponent: null
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        visible: root.page === "hardware" && root._vehicle

        Repeater {
            model: !root._vehicle ? [] : [qsTr("Vehicle ID: %1").arg(root._vehicle.id), qsTr("Firmware: %1").arg(root._vehicle.firmwareTypeString), qsTr("Vehicle Type: %1").arg(root._vehicle.vehicleTypeString), qsTr("Firmware Version: %1.%2.%3").arg(root._vehicle.firmwareMajorVersion).arg(root._vehicle.firmwareMinorVersion).arg(root._vehicle.firmwarePatchVersion)]

            QGCLabel {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
            }
        }

        QGCLabel {
            text: root._vehicle ? qsTr("Messages Received: %1").arg(root._vehicle.messagesReceived) : ""
        }

        QGCLabel {
            text: root._vehicle ? qsTr("Messages Sent: %1").arg(root._vehicle.messagesSent) : ""
        }

        Item {
            Layout.fillHeight: true
        }
    }

    ConfiguratorTelemetryPlot {
        Layout.fillHeight: true
        Layout.fillWidth: true
        series: !root._vehicle ? [] : [
            {
                title: qsTr("Roll"),
                fact: root._vehicle.roll
            },
            {
                title: qsTr("Pitch"),
                fact: root._vehicle.pitch
            },
            {
                title: qsTr("Heading"),
                fact: root._vehicle.heading
            }
        ]
        title: qsTr("Attitude and Angular Rates")
        visible: root.page === "waveforms" && root.tab === 0 && root._vehicle
    }
}
