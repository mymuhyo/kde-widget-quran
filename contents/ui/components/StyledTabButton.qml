import QtQuick
import QtQuick.Controls
import "../models" as Models

TabButton {
    id: control

    property bool narrowLayout: false
    property real scaleFactor: 1.0

    font.bold: checked

    contentItem: Row {
        spacing: 6
        anchors.centerIn: parent
        
        // Use Kirigami icon if available (assuming icon property is set via parent)
        // We handle this by checking if the icon property was assigned
        Image {
            source: control.icon.name ? "image://icon/" + control.icon.name : ""
            width: source != "" ? Math.round(16 * control.scaleFactor) : 0
            height: width
            visible: source != ""
            anchors.verticalCenter: parent.verticalCenter
            
            // Simple color overlay approach for icons
            layer.enabled: true
            layer.effect: ShaderEffect {
                property color color: control.checked ? "#F5F7FA" : Models.PlaybackManager.colorTextPrimary
                fragmentShader: "
                    varying highp vec2 qt_TexCoord0;
                    uniform highp sampler2D source;
                    uniform highp vec4 color;
                    void main() {
                        gl_FragColor = texture2D(source, qt_TexCoord0).a * color;
                    }
                "
            }
        }

        Text {
            text: control.text
            color: control.checked ? "#F5F7FA" : Models.PlaybackManager.colorTextPrimary
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
        radius: 8
        color: control.checked ? Models.PlaybackManager.colorAccent : "transparent"

        border.width: control.hovered && !control.checked ? 1 : 0
        border.color: Models.PlaybackManager.colorBorder

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}
