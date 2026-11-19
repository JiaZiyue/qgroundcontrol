pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick

Item {
    id: root

    readonly property bool _connected: vehicle && !vehicle.vehicleLinkManager.communicationLost
    readonly property real _heading: _connected && isFinite(vehicle.heading.rawValue) ? vehicle.heading.rawValue : 0
    readonly property real _pitch: _connected && isFinite(vehicle.pitch.rawValue) ? vehicle.pitch.rawValue : 0
    readonly property real _roll: _connected && isFinite(vehicle.roll.rawValue) ? vehicle.roll.rawValue : 0
    property var vehicle: null

    function repaint() {
        if (instrument) { instrument.requestPaint() }
    }

    clip: true

    on_HeadingChanged: repaint()
    on_PitchChanged: repaint()
    on_RollChanged: repaint()

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    Canvas {
        id: instrument

        anchors.fill: parent

        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const scale = height / 70;
            const span = Math.max(width, height) * 4;
            ctx.save();
            ctx.translate(width / 2, height / 2);
            ctx.rotate(-root._roll * Math.PI / 180);
            const horizon = root._pitch * scale;
            ctx.fillStyle = qgcPal.instrumentSky;
            ctx.fillRect(-span, -span, span * 2, span + horizon);
            ctx.fillStyle = qgcPal.instrumentGround;
            ctx.fillRect(-span, horizon, span * 2, span);
            ctx.strokeStyle = qgcPal.instrumentMark;
            ctx.fillStyle = qgcPal.instrumentMark;
            ctx.font = ScreenTools.defaultFontPixelHeight + "px monospace";
            ctx.textAlign = "center";
            for (let angle = -90; angle <= 90; angle += 5) {
                const y = horizon - angle * scale;
                const length = width * (angle % 10 === 0 ? 0.4 : 0.22);
                ctx.lineWidth = angle === 0 ? 2 : 1;
                ctx.beginPath();
                ctx.moveTo(-length / 2, y);
                ctx.lineTo(length / 2, y);
                ctx.stroke();
                if (angle !== 0 && angle % 10 === 0) {
                    ctx.fillText(angle.toString(), -length / 2 - ScreenTools.defaultFontPixelHeight, y);
                    ctx.fillText(angle.toString(), length / 2 + ScreenTools.defaultFontPixelHeight, y);
                }
            }
            ctx.restore();
            ctx.strokeStyle = qgcPal.instrumentMark;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(width * 0.28, height / 2);
            ctx.lineTo(width * 0.42, height / 2);
            ctx.lineTo(width * 0.42, height / 2 + ScreenTools.defaultFontPixelHeight / 2);
            ctx.moveTo(width * 0.58, height / 2 + ScreenTools.defaultFontPixelHeight / 2);
            ctx.lineTo(width * 0.58, height / 2);
            ctx.lineTo(width * 0.72, height / 2);
            ctx.stroke();
            const compassY = height - ScreenTools.defaultFontPixelHeight * 2;
            ctx.fillStyle = qgcPal.instrumentGround;
            ctx.fillRect(width * 0.15, compassY - ScreenTools.defaultFontPixelHeight, width * 0.7, ScreenTools.defaultFontPixelHeight * 2);
            ctx.fillStyle = qgcPal.instrumentMark;
            ctx.textAlign = "center";
            ctx.font = ScreenTools.smallFontPixelHeight + "px monospace";
            for (let offset = -30; offset <= 30; offset += 10) {
                const x = width / 2 + offset * width / 100;
                ctx.fillText(Math.round((root._heading + offset + 360) % 360).toString(), x, compassY);
            }
            ctx.beginPath();
            ctx.moveTo(width / 2 - 5, compassY - ScreenTools.defaultFontPixelHeight);
            ctx.lineTo(width / 2 + 5, compassY - ScreenTools.defaultFontPixelHeight);
            ctx.lineTo(width / 2, compassY - ScreenTools.defaultFontPixelHeight / 2);
            ctx.closePath();
            ctx.fill();
        }
        onWidthChanged: requestPaint()
    }

    QGCLabel {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: qgcPal.instrumentMark
        text: root._connected ? qsTr("Roll %1°   Pitch %2°   Heading %3°").arg(root._roll.toFixed(1)).arg(root._pitch.toFixed(1)).arg(root._heading.toFixed(0)) : qsTr("No attitude telemetry")
    }

    Connections {
        function onPaletteChanged() { root.repaint() }

        target: qgcPal
    }
}
