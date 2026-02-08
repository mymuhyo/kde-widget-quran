import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    property var controller
    readonly property real scaleFactor: controller && controller.uiScale ? controller.uiScale : 1.0
    readonly property color textColor: controller ? controller.colorTextPrimary : "#1A222C"
    readonly property color borderColor: controller ? controller.colorBorder : "#CDD5DE"
    readonly property color fieldColor: controller ? controller.colorCard : "#FAFCFE"
    readonly property color popupColor: controller ? Qt.lighter(controller.colorCard, 1.02) : "#FFFFFF"
    readonly property color highlightColor: controller
        ? Qt.rgba(controller.colorAccent.r, controller.colorAccent.g, controller.colorAccent.b, 0.22)
        : "#D7E3EF"

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
        y: control.height + 4
        width: control.width
        padding: 4
        implicitHeight: Math.min(
            contentItem.implicitHeight + topPadding + bottomPadding,
            Math.round(320 * control.scaleFactor)
        )

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
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
