pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var _positions: []
    property var gps
    property real radius: 2
    property var vehicle

    function clear() {
        _positions = [];
        if (track) {
            track.requestPaint();
        }
    }

    onGpsChanged: clear()
    onVehicleChanged: clear()

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    RowLayout {
        Layout.margins: ScreenTools.defaultFontPixelWidth

        QGCLabel {
            Layout.fillWidth: true
            text: qsTr("GPS 打点轨迹 · %1 点").arg(root._positions.length)
        }

        QGCComboBox {
            model: ["2 m", "5 m", "10 m", "20 m"]

            onActivated: {
                root.radius = [2, 5, 10, 20][currentIndex];
                track.requestPaint();
            }
        }

        QGCButton {
            text: qsTr("清空")

            onClicked: root.clear()
        }
    }

    Canvas {
        id: track

        Layout.fillHeight: true
        Layout.fillWidth: true

        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = qgcPal.borderSubtle;
            for (let line = 0; line <= 4; ++line) {
                ctx.beginPath();
                ctx.moveTo(width * line / 4, 0);
                ctx.lineTo(width * line / 4, height);
                ctx.moveTo(0, height * line / 4);
                ctx.lineTo(width, height * line / 4);
                ctx.stroke();
            }
            if (!root._positions.length) {
                return;
            }
            const origin = root._positions[0];
            const metersPerDegree = Math.PI * 6378137 / 180;
            const scale = Math.min(width, height) / (2 * root.radius);
            ctx.strokeStyle = qgcPal.accent;
            ctx.beginPath();
            for (let index = 0; index < root._positions.length; ++index) {
                const point = root._positions[index];
                const x = width / 2 + (point.lon - origin.lon) * metersPerDegree * Math.cos(origin.lat * Math.PI / 180) * scale;
                const y = height / 2 - (point.lat - origin.lat) * metersPerDegree * scale;
                if (index === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();
        }
        onWidthChanged: requestPaint()

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("等待有效 GPS 定位…")
            visible: root._positions.length === 0
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.vehicle && !root.vehicle.vehicleLinkManager.communicationLost

        onTriggered: {
            if (!root.gps || root.gps.lock.rawValue < 3) {
                return;
            }
            const lat = Number(root.gps.lat.rawValue);
            const lon = Number(root.gps.lon.rawValue);
            if (!isFinite(lat) || !isFinite(lon)) {
                return;
            }
            const positions = root._positions.slice(-599);
            positions.push({
                lat: lat,
                lon: lon
            });
            root._positions = positions;
            track.requestPaint();
        }
    }
}
