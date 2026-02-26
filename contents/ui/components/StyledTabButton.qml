import QtQuick
import QtQuick.Controls
import "../models" as Models

TabButton {
    id: control

    property bool narrowLayout: false
    property real scaleFactor: 1.0

    font.bold: checked

    contentItem: Text {
        text: control.text
        color: control.checked ? "#F5F7FA" : Models.PlaybackManager.colorTextPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        font.pixelSize: Math.round((control.narrowLayout ? 12 : 13) * control.scaleFactor)
        font.weight: control.checked ? Font.DemiBold : Font.Normal
    }

    background: Rectangle {
        radius: 8
        color: control.checked ? Models.PlaybackManager.colorAccent : "transparent"

        border.width: control.hovered && !control.checked ? 1 : 0
        border.color: Models.PlaybackManager.colorBorder

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}
