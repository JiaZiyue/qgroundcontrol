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
        text: qsTr("参数配置 · 功能目录")
    }

    QGCLabel {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: ScreenTools.defaultFontPixelHeight
        horizontalAlignment: Text.AlignHCenter
        text: !root._vehicle ? qsTr("请先连接飞机以查看参数目录。") : root._vehicle.parameterManager.missingParameters ? qsTr("参数下载不完整，请重新下载参数后查看目录。") : qsTr("正在下载参数，请稍候…")
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
