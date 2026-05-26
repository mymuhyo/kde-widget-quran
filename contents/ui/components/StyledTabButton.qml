import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../models" as Models

TabButton {
    id: control

    property bool narrowLayout: false
    property real scaleFactor: 1.0

    font.bold: checked

    SystemPalette {
        id: activePal
        colorGroup: SystemPalette.Active
    }

    contentItem: Row {
        id: contentRow
        spacing: 6
        anchors.centerIn: parent
        scale: control.hovered && !control.checked ? 1.02 : 1.0
        opacity: control.checked ? 1.0 : (control.hovered ? 0.95 : 0.7)
        
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        Kirigami.Icon {
            source: control.icon.name || ""
            width: source != "" ? Math.round(16 * control.scaleFactor) : 0
            height: width
            visible: source != ""
            anchors.verticalCenter: parent.verticalCenter
            color: control.checked ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorTextPrimary
        }

        Text {
            text: control.text
            color: control.checked ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorTextPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pixelSize: Math.round((control.narrowLayout ? 12 : 13) * control.scaleFactor)
            font.weight: control.checked ? Font.DemiBold : Font.Normal
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    background: Rectangle {
        color: control.hovered ? Models.PlaybackManager.colorSurfaceMuted : "transparent"
        radius: 6

        Rectangle {
            id: indicator
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Math.round(12 * control.scaleFactor)
            anchors.rightMargin: Math.round(12 * control.scaleFactor)
            height: Math.round(3 * control.scaleFactor)
            radius: height / 2
            color: Models.PlaybackManager.colorAccent
            opacity: control.checked ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }

        border.width: control.activeFocus ? 2 : 0
        border.color: Models.PlaybackManager.focusRingColor

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}
