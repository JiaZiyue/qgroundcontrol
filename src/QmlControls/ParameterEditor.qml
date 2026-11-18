import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Item {
    id:         _root

    property bool functionalDirectory: false

    property alias searchFilterText: searchText.text

    property Fact   _editorDialogFact: Fact { }
    property int    _rowHeight:         ScreenTools.defaultFontPixelHeight * 2
    property int    _rowWidth:          10 // Dynamic adjusted at runtime
    property bool   _searchFilter:      searchText.text.trim() != "" || controller.showModifiedOnly || controller.showFavoritesOnly  ///< true: showing results of search
    property var    _searchResults      ///< List of parameter names from search results
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _showRCToParam:     _activeVehicle && _activeVehicle.px4Firmware
    property var    _appSettings:       QGroundControl.settingsManager.appSettings
    property var    _controller:        controller
    property var    _favorites:         controller.favoriteParameterNames
    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2

    function directoryTitle(name) {
        const titles = {
            "Standard": qsTr("常用功能"), "Advanced": qsTr("高级功能"),
            "Other": qsTr("其他功能"), "Miscellaneous": qsTr("其他功能"),
            "Battery": qsTr("电池与电源"), "Battery Calibration": qsTr("电池校准"),
            "Commander": qsTr("飞行状态与解锁"), "Flight Modes": qsTr("飞行模式"),
            "Sensors": qsTr("传感器"), "Sensor Calibration": qsTr("传感器校准"),
            "GPS": qsTr("卫星定位（GPS）"), "EKF2": qsTr("状态估计（EKF2）"),
            "EKF3": qsTr("状态估计（EKF3）"), "Radio": qsTr("遥控器"),
            "RC": qsTr("遥控器"), "Telemetry": qsTr("遥测通信"), "MAVLink": qsTr("MAVLink 通信"),
            "Multicopter Attitude Control": qsTr("多旋翼姿态控制"),
            "Multicopter Position Control": qsTr("多旋翼位置控制"),
            "Multicopter Rate Control": qsTr("多旋翼角速度控制"),
            "Fixed Wing Attitude Control": qsTr("固定翼姿态控制"),
            "Fixed Wing Position Control": qsTr("固定翼位置控制"),
            "Mission": qsTr("任务航线"), "Navigator": qsTr("导航"), "Geofence": qsTr("地理围栏"),
            "Return Mode": qsTr("返航"), "Land Detector": qsTr("着陆检测"),
            "Safety": qsTr("安全保护"), "Logging": qsTr("日志记录"), "Logger": qsTr("日志记录"),
            "Camera": qsTr("相机"), "Gimbal": qsTr("云台"), "System": qsTr("系统设置")
        }
        return functionalDirectory ? (titles[name] || name) : name
    }

    ParameterEditorController {
        id: controller
    }

    Timer {
        id:         clearTimer
        interval:   100;
        running:    false;
        repeat:     false
        onTriggered: {
            searchText.text = ""
            controller.searchText = ""
        }
    }

    QGCMenu {
        id:                 toolsMenu
        QGCMenuItem {
            text:           qsTr("Refresh")
            onTriggered:	controller.refresh()
        }
        QGCMenuItem {
            text:           qsTr("Reset all to firmware's defaults")
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reset All"),
                                                         qsTr("Select Reset to reset all parameters to their defaults.\n\nNote that this will also completely reset everything, including UAVCAN nodes, all vehicle settings, setup and calibrations."),
                                                         Dialog.Cancel | Dialog.Reset,
                                                         function() { controller.resetAllToDefaults() })
        }
        QGCMenuItem {
            text:           qsTr("Reset to vehicle's configuration defaults")
            visible:        _activeVehicle && !_activeVehicle.apmFirmware
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reset All"),
                                                         qsTr("Select Reset to reset all parameters to the vehicle's configuration defaults."),
                                                         Dialog.Cancel | Dialog.Reset,
                                                         function() { controller.resetAllToVehicleConfiguration() })
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            objectName:     "parameterEditor_toolLoadFromFile"
            text:           qsTr("Load from file for review...")
            onTriggered: {
                fileDialog.title =          qsTr("Load Parameters")
                fileDialog.openForLoad()
            }
        }
        QGCMenuItem {
            text:           qsTr("Save to file...")
            onTriggered: {
                fileDialog.title =          qsTr("Save Parameters")
                fileDialog.openForSave()
            }
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            text:           qsTr("Clear all favorites")
            onTriggered:    controller.clearAllFavorites()
        }
        QGCMenuSeparator { visible: _showRCToParam }
        QGCMenuItem {
            text:           qsTr("Clear all RC to Param")
            onTriggered:	_activeVehicle.clearAllParamMapRC()
            visible:        _showRCToParam
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            text:           qsTr("Reboot Vehicle")
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reboot Vehicle"),
                                                         qsTr("Select Ok to reboot vehicle."),
                                                         Dialog.Cancel | Dialog.Ok,
                                                         function() { _activeVehicle.rebootVehicle() })
        }
    }


    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings.parameterSavePath
        nameFilters:    [ qsTr("Parameter Files (*.%1)").arg(_appSettings.parameterFileExtension), qsTr("Mission Planner Files (*.param)"), qsTr("All Files (*)") ]

        onAcceptedForSave: (file) => {
            controller.saveToFile(file)
            close()
        }

        onAcceptedForLoad: (file) => {
            close()
            if (controller.buildDiffFromFile(file)) {
                parameterDiffDialogFactory.open()
            }
        }
    }

    QGCPopupDialogFactory {
        id: editorDialogFactory

        dialogComponent: editorDialogComponent
    }

    Component {
        id: editorDialogComponent

        ParameterEditorDialog {
            fact:           _editorDialogFact
            showRCToParam:  _showRCToParam
        }
    }

    QGCPopupDialogFactory {
        id: parameterDiffDialogFactory

        dialogComponent: parameterDiffDialog
    }

    Component {
        id: parameterDiffDialog

        ParameterDiffDialog {
            paramController: _controller
        }
    }

    RowLayout {
        id:             header
        anchors.left:   parent.left
        anchors.right:  parent.right

        RowLayout {
            Layout.alignment:   Qt.AlignLeft
            spacing:            ScreenTools.defaultFontPixelWidth

            QGCTextField {
                id:                     searchText
                placeholderText:        (_root.functionalDirectory ? qsTr("搜索参数名称或功能说明…") : qsTr("Search"))
                onDisplayTextChanged:   controller.searchText = displayText
            }

            QGCButton {
                text: (_root.functionalDirectory ? qsTr("清除") : qsTr("Clear"))
                onClicked: {
                    if(ScreenTools.isMobile) {
                        Qt.inputMethod.hide();
                    }
                    clearTimer.start()
                }
            }

            QGCCheckBox {
                text:       (_root.functionalDirectory ? qsTr("隐藏只读参数") : qsTr("Hide read-only"))
                checked:    controller.hideReadOnly
                onClicked:  controller.hideReadOnly = checked
            }
        }

        QGCButton {
            Layout.alignment:   Qt.AlignRight
            objectName:         "parameterEditor_toolsButton"
            text:               (_root.functionalDirectory ? qsTr("参数工具") : qsTr("Tools"))
            onClicked:          toolsMenu.popup()
        }
    }

    QGCGroupBox {
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        header.bottom
        anchors.topMargin:  _margins
        anchors.bottom:     parent.bottom
        showDividers:       false
        contentSpacing:     0

        onCurrentIndexChanged: {
            controller.showModifiedOnly  = (currentIndex === 1)
            controller.showFavoritesOnly = (currentIndex === 2)
        }

        QGCGroupBoxTab { title: (_root.functionalDirectory ? qsTr("全部参数") : qsTr("Full List")) }
        QGCGroupBoxTab { title: (_root.functionalDirectory ? qsTr("已修改") : qsTr("Modified")) }
        QGCGroupBoxTab { title: (_root.functionalDirectory ? qsTr("收藏") : qsTr("Favorites")) }

        Item {
            Layout.fillWidth:   true
            Layout.fillHeight:  true

            /// Group buttons
            QGCFlickable {
                id :                groupScroll
                objectName:          "parameterDirectory_scroll"
                width:              ScreenTools.defaultFontPixelWidth * (_root.functionalDirectory ? 32 : 25)
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                clip:               true
                pixelAligned:       true
                contentHeight:      groupedViewCategoryColumn.height
                flickableDirection: Flickable.VerticalFlick
                visible:            !_searchFilter

                ColumnLayout {
                    id:             groupedViewCategoryColumn
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)

                    Repeater {
                        model: controller.categories

                        Column {
                            Layout.fillWidth:   true
                            spacing:            Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)


                            SectionHeader {
                                id:             categoryHeader
                                anchors.left:   parent.left
                                anchors.right:  parent.right
                                text:           _root.directoryTitle(object.name)
                                checked:        object == controller.currentCategory

                                onCheckedChanged: {
                                    if (checked) {
                                        controller.currentCategory  = object
                                    }
                                }
                            }

                            Repeater {
                                model: categoryHeader.checked ? object.groups : 0

                                QGCButton {
                                    width:          groupScroll.width
                                    text:           _root.directoryTitle(object.name) + (_root.functionalDirectory ? " (" + object.facts.rowCount + ")" : "")
                                    objectName:     "parameterDirectory_group_" + object.name
                                    height:         _rowHeight
                                    checked:        object == controller.currentGroup
                                    autoExclusive:  true

                                    onClicked: {
                                        if (!checked) _rowWidth = 10
                                        checked = true
                                        controller.currentGroup = object
                                    }
                                }
                            }
                        }
                    }
                }
            }

            HorizontalHeaderView {
                id:                 headerView
                anchors.left:       tableView.left
                anchors.right:      tableView.right
                anchors.top:        parent.top
                syncView:           tableView
                clip:               true

                delegate: Rectangle {
                    implicitWidth:  column === 0 ? ScreenTools.implicitCheckBoxHeight + ScreenTools.defaultFontPixelWidth
                                                 : headerLabel.contentWidth + ScreenTools.defaultFontPixelWidth
                    implicitHeight: headerLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.5
                    color:          qgcPal.windowCard

                    QGCLabel {
                        id:                     headerLabel
                        anchors.left:           parent.left
                        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
                        anchors.verticalCenter: parent.verticalCenter
                        text:                   _root.functionalDirectory ? [qsTr("收藏"), qsTr("参数名称"), qsTr("当前值"), qsTr("功能说明")][column] : display
                        font.bold:              true
                    }

                    // Top border
                    Rectangle {
                        anchors.top:    parent.top
                        width:          parent.width
                        height:         1
                        color:          qgcPal.borderSubtle
                    }

                    // Left border
                    Rectangle {
                        anchors.left:   parent.left
                        height:         parent.height
                        width:          1
                        color:          qgcPal.borderSubtle
                    }

                    // Right border (last column only)
                    Rectangle {
                        anchors.right:  parent.right
                        height:         parent.height
                        width:          1
                        color:          qgcPal.borderSubtle
                        visible:        column == 3
                    }

                    // Bottom border
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         1
                        color:          qgcPal.borderSubtle
                    }
                }
            }

            TableView {
                id:                 tableView
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.top:        headerView.bottom
                anchors.bottom:     parent.bottom
                anchors.left:       _searchFilter ? parent.left : groupScroll.right
                anchors.right:      parent.right
                columnSpacing:      0
                rowSpacing:         0
                model:              controller.parameters
                contentWidth:       width
                clip:               true

                // Qt is supposed to adjust column widths automatically when larger widths come into view.
                // But it doesn't work. So we have to do it force a layout manually when we scroll.
                Timer {
                    id:             forceLayoutTimer
                    interval:       500
                    repeat:         false
                    onTriggered:    tableView.forceLayout()
                }

                onTopRowChanged: forceLayoutTimer.start()
                onModelChanged: {
                    positionViewAtRow(0, TableView.AlignLeft | TableView.AlignTop)
                    forceLayoutTimer.start()
                }

                delegate: Rectangle {
                    implicitWidth:  column === 0 ? ScreenTools.implicitCheckBoxHeight + ScreenTools.defaultFontPixelWidth
                                                 : column === 1 ? nameRow.implicitWidth + ScreenTools.defaultFontPixelWidth
                                                 : column === 2 ? ScreenTools.defaultFontPixelWidth * 16
                                                                : label.contentWidth + ScreenTools.defaultFontPixelWidth
                    implicitHeight: label.contentHeight + ScreenTools.defaultFontPixelHeight * 0.5
                    color:          row % 2 === 0 ? "transparent" : qgcPal.windowCard
                    clip:           true

                    // Bottom grid line
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         1
                        color:          qgcPal.borderSubtle
                    }

                    // Left grid line
                    Rectangle {
                        anchors.left:   parent.left
                        height:         parent.height
                        width:          1
                        color:          qgcPal.borderSubtle
                    }

                    // Right grid line (last column only)
                    Rectangle {
                        anchors.right:  parent.right
                        height:         parent.height
                        width:          1
                        color:          qgcPal.borderSubtle
                        visible:        column == 3
                    }

                    QGCCheckBox {
                        visible:                column === 0
                        anchors.centerIn:       parent
                        checked:                _root._favorites.indexOf(fact.name) >= 0
                        z:                      1
                        onClicked:              controller.toggleFavorite(fact.name)
                    }

                    Row {
                        id:                     nameRow
                        visible:                column === 1
                        anchors.left:           parent.left
                        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing:               lockIcon.visible ? ScreenTools.defaultFontPixelWidth / 3 : 0

                        QGCLabel {
                            text:               column === 1 ? display : ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCColoredImage {
                            id:                 lockIcon
                            visible:            fact.readOnly
                            source:             "qrc:/InstrumentValueIcons/lock-closed.svg"
                            color:              qgcPal.textPrimary
                            width:              ScreenTools.defaultFontPixelHeight * 0.8
                            height:             width
                            sourceSize.width:   width
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    QGCLabel {
                        id:                 label
                        visible:            column !== 0 && column !== 1
                        anchors.left:       parent.left
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width:              column == 2 ? ScreenTools.defaultFontPixelWidth * 15 : implicitWidth
                        text:               column == 2 ? col1String() : display
                        color:              column == 2 && fact.defaultValueAvailable && !fact.valueEqualsDefault ? qgcPal.modifiedParamValue : qgcPal.textPrimary
                        font.bold:          column == 2 && fact.defaultValueAvailable && !fact.valueEqualsDefault
                        maximumLineCount:   1
                        elide:              column == 2 ? Text.ElideRight : Text.ElideNone

                        function col1String() {
                            if (fact.enumStrings.length === 0) {
                                return fact.valueString + " " + fact.units
                            }
                            if (fact.bitmaskStrings.length != 0) {
                                return fact.selectedBitmaskStrings.join(',')
                            }
                            return fact.enumStringValue
                        }
                    }

                    QGCMouseArea {
                        anchors.fill: parent
                        visible:      column !== 0
                        onClicked: mouse => {
                            _editorDialogFact = fact
                            editorDialogFactory.open()
                        }
                    }
                }
            }
        }
    }
}
