pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls
import QtQml.Models

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property var detectedPorts: []
    property bool _userSelected: false
    required property QtObject navigationHost
    property var selectedConfiguration: null

    function connectionType(configuration) {
        if (!configuration) return ""
        switch (configuration.linkType) {
        case LinkConfiguration.TypeSerial: return qsTr("串口")
        case LinkConfiguration.TypeUdp: return "UDP"
        case LinkConfiguration.TypeTcp: return "TCP"
        case LinkConfiguration.TypeBluetooth: return qsTr("蓝牙")
        case LinkConfiguration.TypeLogReplay: return qsTr("日志回放")
        default: return qsTr("其他")
        }
    }

    function connectPort(port, label) {
        const manager = QGroundControl.linkManager;
        for (let i = 0; i < manager.linkConfigurations.count; ++i) {
            const configuration = manager.linkConfigurations.get(i);
            if (configuration.linkType === LinkConfiguration.TypeSerial && configuration.portName === port) {
                if (configuration.name === port) {
                    configuration.name = label;
                }
                selectedConfiguration = configuration;
                _userSelected = true;
                manager.createConnectedLink(configuration);
                return;
            }
        }
        const configuration = manager.createConfiguration(LinkConfiguration.TypeSerial, label);
        if (!configuration) {
            return;
        }
        configuration.portName = port;
        configuration.baud = 115200;
        configuration.autoConnect = false;
        manager.endCreateConfiguration(configuration);
        selectedConfiguration = configuration;
        _userSelected = true;
        manager.createConnectedLink(configuration);
    }

    function selectAvailable() {
        if (_userSelected && selectedConfiguration) {
            return;
        }
        let first = null;
        for (let index = 0; index < configurations.count; ++index) {
            const item = configurations.objectAt(index);
            if (!item) {
                continue;
            }
            if (!first) {
                first = item.configuration;
            }
            if (item.configuration.linkActive) {
                selectedConfiguration = item.configuration;
                return;
            }
        }
        selectedConfiguration = first;
    }

    spacing: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: connectionPalette }

    QGCLabel {
        objectName: "connection_status"
        text: !root.selectedConfiguration ? qsTr("未连接")
            : (root.selectedConfiguration.linkActive ? qsTr("链路已连接 · %1") : qsTr("未连接 · %1"))
                .arg(root.connectionType(root.selectedConfiguration))
        color: root.selectedConfiguration && root.selectedConfiguration.linkActive
            ? connectionPalette.successText : connectionPalette.textSecondary
        font.bold: true
    }

    QGCButton {
        id: selector

        objectName: "connection_selector"
        text: root.selectedConfiguration ? root.selectedConfiguration.name : qsTr("选择连接")

        onClicked: connectionMenu.open()

        QGCMenu {
            id: connectionMenu

            y: selector.height
            onAboutToShow: {
                const manager = QGroundControl.linkManager;
                const ports = manager.serialPorts || [];
                const names = manager.serialPortStrings || [];
                root.detectedPorts = ports.map((port, index) => ({
                    port: port,
                    label: names[index] && names[index] !== port
                        ? names[index] + "（" + port + "）" : port
                }));
            }

            Instantiator {
                model: root.detectedPorts
                delegate: QGCMenuItem {
                    required property var modelData
                    text: qsTr("串口：%1").arg(modelData.label)
                    onTriggered: root.connectPort(modelData.port, modelData.label)
                }
                onObjectAdded: (index, item) => connectionMenu.addItem(item)
                onObjectRemoved: (index, item) => connectionMenu.removeItem(item)
            }

            QGCMenuItem {
                text: qsTr("未检测到串口设备")
                enabled: false
                visible: root.detectedPorts.length === 0
            }

            Instantiator {
                id: configurations

                model: QGroundControl.linkManager.linkConfigurations

                delegate: QGCMenuItem {
                    id: configurationItem

                    readonly property var configuration: object
                    required property var object

                    checkable: true
                    checked: root.selectedConfiguration === object
                    objectName: "connection_option_" + object.name
                    text: object.name + (object.linkActive ? qsTr("（已启用）") : "")

                    onTriggered: {
                        root._userSelected = true;
                        root.selectedConfiguration = object;
                        if (!object.linkActive) {
                            QGroundControl.linkManager.createConnectedLink(object);
                        }
                    }

                    Connections {
                        function onLinkActiveChanged() {
                            root.selectAvailable();
                        }

                        target: configurationItem.object
                    }
                }

                onObjectAdded: (index, item) => {
                    connectionMenu.insertItem(index, item);
                    if (!root.selectedConfiguration || (!root._userSelected && item.configuration.linkActive)) {
                        root.selectedConfiguration = item.configuration;
                    }
                }
                onObjectRemoved: (index, item) => {
                    if (root.selectedConfiguration === item.configuration) {
                        root.selectedConfiguration = null;
                        root._userSelected = false;
                    }
                    connectionMenu.removeItem(item);
                    Qt.callLater(root.selectAvailable);
                }
            }

            QGCMenuItem {
                text: qsTr("管理连接…")

                onTriggered: {
                    if (root.navigationHost.allowViewSwitch()) {
                        root.navigationHost.showSettingsTool("Comm Links");
                    }
                }
            }
        }
    }

    QGCButton {
        enabled: true
        objectName: "connection_toggle"
        text: root.selectedConfiguration && root.selectedConfiguration.linkActive ? qsTr("断开") : qsTr("连接")

        onClicked: {
            const configuration = root.selectedConfiguration;
            if (configuration && configuration.linkActive) {
                QGroundControl.linkManager.disconnectLinkConfiguration(configuration);
            } else {
                connectionMenu.open();
            }
        }
    }
}
