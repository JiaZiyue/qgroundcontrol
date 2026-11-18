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
    readonly property var _tabs: page === "messages" ? [qsTr("飞行消息"), qsTr("MAVLink 消息"), qsTr("系统控制台")] : page === "logs" ? [qsTr("机载日志"), qsTr("本地日志分析")] : page === "waveforms" ? [qsTr("实时波形"), qsTr("MAVLink 字段波形")] : []
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
                messages: qsTr("消息控制台"),
                logs: qsTr("日志"),
                waveforms: qsTr("波形"),
                firmware: qsTr("固件升级"),
                hardware: qsTr("硬件信息")
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
        text: root._vehicle ? qsTr("日志记录条件：正在等待飞控参数加载完成。") : qsTr("日志记录条件：请先连接飞控。")
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
                        "-1": qsTr("禁用日志记录"),
                        "0": qsTr("解锁后记录，上锁后停止"),
                        "1": qsTr("开机后记录，首次上锁后停止"),
                        "2": qsTr("开机后持续记录，关机后停止"),
                        "3": qsTr("遥控器 AUX1 输入大于 30% 时记录"),
                        "4": qsTr("首次解锁后持续记录，关机后停止")
                    };
                    return labels[String(value)] || original;
                }
                if (Number(value) === 0) {
                    return qsTr("仅解锁时记录");
                }
                if (Number(value) === 1) {
                    return qsTr("未解锁时也记录");
                }
                return original;
            }

            FactPanelController {
                id: controller
            }

            RowLayout {
                Layout.fillWidth: true

                QGCLabel {
                    text: qsTr("日志记录条件")
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
                    text: loggingSettings.modeFact ? loggingSettings.modeFact.name : qsTr("当前飞控未提供日志记录条件参数")
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: !loggingSettings.modeFact ? "" : root._vehicle && root._vehicle.armed
                    ? qsTr("请先上锁，再修改记录条件。")
                    : loggingSettings.modeFact.vehicleRebootRequired
                        ? qsTr("修改后保存到飞控，重启飞控后生效。此设置控制机载日志，实际记录还取决于日志后端及存储状态。")
                        : qsTr("修改后保存到飞控。实际记录还取决于日志后端及存储状态。")
            }
        }
    }

    QGCLabel {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("请先连接飞机。")
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
            model: !root._vehicle ? [] : [qsTr("飞机编号：%1").arg(root._vehicle.id), qsTr("飞控固件：%1").arg(root._vehicle.firmwareTypeString), qsTr("机型：%1").arg(root._vehicle.vehicleTypeString), qsTr("固件版本：%1.%2.%3").arg(root._vehicle.firmwareMajorVersion).arg(root._vehicle.firmwareMinorVersion).arg(root._vehicle.firmwarePatchVersion)]

            QGCLabel {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
            }
        }

        QGCLabel {
            text: root._vehicle ? qsTr("已接收消息：%1").arg(root._vehicle.messagesReceived) : ""
        }

        QGCLabel {
            text: root._vehicle ? qsTr("已发送消息：%1").arg(root._vehicle.messagesSent) : ""
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
                title: qsTr("横滚角"),
                fact: root._vehicle.roll
            },
            {
                title: qsTr("俯仰角"),
                fact: root._vehicle.pitch
            },
            {
                title: qsTr("航向角"),
                fact: root._vehicle.heading
            }
        ]
        title: qsTr("姿态与角速度")
        visible: root.page === "waveforms" && root.tab === 0 && root._vehicle
    }
}
