pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    readonly property var _colors: [qgcPal.accent, qgcPal.colorGreen, qgcPal.colorOrange, qgcPal.colorRed]
    readonly property bool _connected: vehicle && !vehicle.vehicleLinkManager.communicationLost
    property var _history: []
    readonly property int sampleCount: _history.length
    property bool paused: false
    required property var series
    required property string title
    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle

    function clear() {
        _history = [];
        if (chart) {
            chart.requestPaint();
        }
    }

    function sample(entry) {
        return entry.fact ? Number(entry.fact.value) : entry.field && entry.field.value !== "" ? Number(entry.field.value) * (entry.scale === undefined ? 1 : entry.scale) : NaN;
    }

    border.color: qgcPal.borderSubtle
    color: qgcPal.windowCard
    implicitHeight: ScreenTools.defaultFontPixelHeight * 15
    radius: ScreenTools.defaultFontPixelHeight / 2

    onSeriesChanged: clear()
    onVehicleChanged: clear()
    on_ConnectedChanged: clear()

    QGCPalette {
        id: qgcPal

        colorGroupEnabled: root.enabled
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelHeight / 2

        RowLayout {
            Layout.fillWidth: true

            QGCLabel {
                Layout.fillWidth: true
                font.bold: true
                text: root.title
            }

            QGCButton {
                text: root.paused ? qsTr("Resume") : qsTr("Pause")

                onClicked: root.paused = !root.paused
            }

            QGCButton {
                text: qsTr("Clear")

                onClicked: root.clear()
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelHeight

            Repeater {
                model: root.series

                QGCLabel {
                    required property int index
                    required property var modelData

                    color: root._colors[index % root._colors.length]
                    text: qsTr("%1: %2").arg(modelData.title)
                        .arg(root._connected && isFinite(root.sample(modelData))
                            ? (modelData.fact ? modelData.fact.valueString + " " + modelData.fact.units
                                : root.sample(modelData).toFixed(3) + " " + modelData.units)
                            : "—")
                }
            }
        }

        Canvas {
            id: chart

            Layout.fillHeight: true
            Layout.fillWidth: true

            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = qgcPal.borderSubtle;
                ctx.lineWidth = 1;
                for (let row = 0; row <= 4; ++row) {
                    const y = row * height / 4;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }
                const points = root._history;
                if (points.length < 2) {
                    return;
                }
                let minimum = Infinity;
                let maximum = -Infinity;
                for (const point of points) {
                    for (const value of point.values) {
                        if (isFinite(value)) {
                            minimum = Math.min(minimum, value);
                            maximum = Math.max(maximum, value);
                        }
                    }
                }
                if (!isFinite(minimum)) {
                    return;
                }
                const margin = Math.max((maximum - minimum) * 0.1, 0.01);
                minimum -= margin;
                maximum += margin;
                const start = points[0].time;
                const duration = Math.max(1, points[points.length - 1].time - start);
                ctx.fillStyle = qgcPal.textSecondary;
                ctx.font = ScreenTools.smallFontPixelHeight + "px sans-serif";
                ctx.fillText(maximum.toFixed(2), 0, ScreenTools.smallFontPixelHeight);
                ctx.fillText(minimum.toFixed(2), 0, height);
                for (let seriesIndex = 0; seriesIndex < root.series.length; ++seriesIndex) {
                    ctx.strokeStyle = root._colors[seriesIndex % root._colors.length];
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    let drawing = false;
                    for (const point of points) {
                        const value = point.values[seriesIndex];
                        if (!isFinite(value)) {
                            drawing = false;
                            continue;
                        }
                        const x = (point.time - start) * width / duration;
                        const y = height - (value - minimum) * height / (maximum - minimum);
                        if (drawing) {
                            ctx.lineTo(x, y);
                        } else {
                            ctx.moveTo(x, y);
                            drawing = true;
                        }
                    }
                    ctx.stroke();
                }
            }
            onWidthChanged: requestPaint()

            QGCLabel {
                anchors.centerIn: parent
                text: qsTr("Waiting for sensor data…")
                visible: root._history.length === 0
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.visible && root._connected && !root.paused

        onTriggered: {
            const values = root.series.map(entry => root.sample(entry));
            if (!values.some(value => isFinite(value))) {
                return;
            }
            const points = root._history.slice(-299);
            points.push({
                time: Date.now(),
                values: values
            });
            root._history = points;
            chart.requestPaint();
        }
    }
}
