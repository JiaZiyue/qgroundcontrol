pragma ComponentBehavior: Bound

import QGroundControl
import QGroundControl.Controls

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    readonly property bool _ready: _vehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !_vehicle.parameterManager.missingParameters
    readonly property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle

    spacing: ScreenTools.defaultFontPixelHeight / 2

    QGCLabel {
        Layout.margins: ScreenTools.defaultFontPixelHeight
        font.bold: true
        font.pointSize: ScreenTools.largeFontPointSize
        text: qsTr("Parameters · Categories")
    }

    QGCLabel {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        horizontalAlignment: Text.AlignHCenter
        text: !root._vehicle ? qsTr("Connect a vehicle to view parameter categories.") : root._vehicle.parameterManager.missingParameters ? qsTr("Parameter download was incomplete. Download the parameters again to view the categories.") : qsTr("Downloading parameters…")
        verticalAlignment: Text.AlignVCenter
        visible: !root._ready
        wrapMode: Text.WordWrap
    }

    Loader {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelWidth
        active: root._ready
        visible: active

        sourceComponent: ParameterEditor {
            functionalDirectory: true
            objectName: "configurator_parameters"
        }
    }
}
