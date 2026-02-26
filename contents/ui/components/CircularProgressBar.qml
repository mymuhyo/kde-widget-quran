import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real progress: 0.0 // 0.0 to 1.0
    property real strokeWidth: 2
    property color colorBg: "#33FFFFFF"
    property color colorFg: "#86D0FF"
    property real radius: Math.min(width, height) / 2
    
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.colorBg
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius - root.strokeWidth / 2
                radiusY: root.radius - root.strokeWidth / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
        
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.colorFg
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius - root.strokeWidth / 2
                radiusY: root.radius - root.strokeWidth / 2
                startAngle: -90
                sweepAngle: root.progress * 360
            }
        }
    }
}
