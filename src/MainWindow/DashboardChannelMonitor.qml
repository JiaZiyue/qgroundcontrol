pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string channelLabelFormat
    property bool connected: false
    required property string title
    property var values: []

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    QGCLabel {
        font.bold: true
        text: root.title
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth

        Repeater {
            model: 12

            ColumnLayout {
                id: channel

                required property int index
                readonly property int value: root.connected && index < root.values.length ? root.values[index] : -1

                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight / 4

                QGCLabel {
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: ScreenTools.smallFontPointSize
                    text: channel.value >= 0 ? channel.value : "—"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4
                    color: qgcPal.windowInset
                    radius: ScreenTools.defaultFontPixelWidth / 2

                    Rectangle {
                        anchors.bottom: parent.bottom
                        color: qgcPal.colorGreen
                        height: parent.height * (channel.value < 0 ? 0 : Math.max(0, Math.min(1, (channel.value - 1000) / 1000)))
                        radius: parent.radius
                        width: parent.width
                    }
                }

                QGCLabel {
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: ScreenTools.smallFontPointSize
                    text: root.channelLabelFormat.arg(channel.index + 1)
                }
            }
        }
    }
}
