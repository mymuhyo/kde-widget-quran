import QtQuick
import "../models" as Models
import QtQuick.Controls

ComboBox {
    id: control

        readonly property real scaleFactor: Models.PlaybackManager.uiScale ? Models.PlaybackManager.uiScale : 1.0
    readonly property color textColor: Models.PlaybackManager.colorTextPrimary
    readonly property color borderColor: Models.PlaybackManager.colorBorder
    readonly property color fieldColor: Models.PlaybackManager.colorCard
    readonly property color popupColor: Qt.lighter(Models.PlaybackManager.colorCard, 1.02)
    readonly property color highlightColor: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.22)

    implicitHeight: Math.max(38, Math.round(40 * scaleFactor))
    leftPadding: Math.round(10 * scaleFactor)
    rightPadding: Math.round(28 * scaleFactor)
    topPadding: Math.round(6 * scaleFactor)
    bottomPadding: Math.round(6 * scaleFactor)
    font.pixelSize: Math.round(14 * scaleFactor)

    contentItem: Text {
        text: control.displayText
        color: control.textColor
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        font: control.font
        leftPadding: 0
        rightPadding: 0
    }

    indicator: Text {
        text: "\u25be"
        color: control.textColor
        font.pixelSize: Math.max(11, Math.round(12 * control.scaleFactor))
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Math.round(10 * control.scaleFactor)
    }

    background: Rectangle {
        radius: 8
        color: control.fieldColor
        border.width: 1
        border.color: control.borderColor
    }

    delegate: ItemDelegate {
        width: control.popup ? control.popup.availableWidth : control.width
        implicitHeight: Math.max(34, Math.round(36 * control.scaleFactor))
        horizontalPadding: Math.round(10 * control.scaleFactor)
        verticalPadding: Math.round(6 * control.scaleFactor)
        highlighted: control.highlightedIndex === index
        
        property bool matchesFilter: {
            if (!control.popup || !control.popup.filterText) return true
            var filter = control.popup.filterText
            if (filter === "") return true
            var txt = control.textAt(index)
            if (!txt) return false
            return txt.toLowerCase().indexOf(filter) !== -1
        }
        
        visible: matchesFilter
        height: visible ? implicitHeight : 0

        contentItem: Text {
            text: control.textAt(index)
            color: control.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Math.round(14 * control.scaleFactor)
        }

        background: Rectangle {
            radius: 6
            color: parent.highlighted ? control.highlightColor : "transparent"
        }
    }

    popup: Popup {
        id: comboPopup
        y: control.height + 4
        width: control.width
        padding: 4
        implicitHeight: Math.min(
            listLayout.implicitHeight + topPadding + bottomPadding,
            Math.round(320 * control.scaleFactor)
        )

        property string filterText: ""

        onOpened: {
            filterText = ""
            if (searchField) searchField.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            id: listLayout
            spacing: 4

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Search...")
                font.pixelSize: Math.round(13 * control.scaleFactor)
                leftPadding: 8
                rightPadding: 8
                topPadding: 6
                bottomPadding: 6
                
                background: Rectangle {
                    color: Qt.darker(control.fieldColor, 1.05)
                    radius: 6
                    border.width: 1
                    border.color: control.borderColor
                }
                
                onTextChanged: comboPopup.filterText = text.toLowerCase()
            }

            ListView {
                id: listView
                clip: true
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                Layout.maximumHeight: Math.round(280 * control.scaleFactor)
                
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }

        background: Rectangle {
            radius: 10
            color: control.popupColor
            border.width: 1
            border.color: control.borderColor
        }
    }
}
