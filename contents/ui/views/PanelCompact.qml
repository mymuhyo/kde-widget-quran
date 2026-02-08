import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var controller
    readonly property real playbackProgress: controller && controller.playbackDurationMs > 0
        ? Math.max(0, Math.min(1, controller.playbackPositionMs / controller.playbackDurationMs))
        : 0
    readonly property bool narrowLayout: width < 230
    readonly property bool ultraCompact: width < 165

    Layout.minimumWidth: 180
    Layout.preferredWidth: 300
    Layout.maximumWidth: 500
    implicitWidth: 300
    implicitHeight: narrowLayout ? 50 : 44
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: controller ? controller.colorPanelStart : "#1F2833" }
            GradientStop { position: 1.0; color: controller ? controller.colorPanelEnd : "#2A3542" }
        }
        border.width: 1
        border.color: controller ? controller.colorBorder : "#335A7A"
    }

    MouseArea {
        id: clickLayer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        z: 0
        onClicked: function(mouse) {
            if (!root.controller) {
                return
            }

            if (mouse.button === Qt.LeftButton) {
                root.controller.expanded = !root.controller.expanded
            } else if (mouse.button === Qt.MiddleButton) {
                root.controller.togglePlayPause()
            } else if (mouse.button === Qt.RightButton) {
                quickMenu.popup()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: narrowLayout ? 5 : 4
        anchors.bottomMargin: narrowLayout ? 12 : 10
        spacing: narrowLayout ? 6 : 8
        z: 1

        Rectangle {
            width: narrowLayout ? 6 : 8
            height: narrowLayout ? 6 : 8
            radius: width / 2
            color: controller && controller.isPlaying ? "#5EDC85" : "#AFC6DA"
        }

        Label {
            Layout.fillWidth: true
            color: controller ? controller.colorPanelText : "#F5F7FA"
            text: controller ? controller.currentTrackLabel() : qsTr("No track")
            elide: Text.ElideRight
            font.pixelSize: narrowLayout ? 11 : 12
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            visible: !ultraCompact
        }

        ToolButton {
            flat: true
            icon.name: controller && controller.isPlaying ? "media-playback-pause" : "media-playback-start"
            enabled: controller && !controller.isQueueLoading
            onClicked: controller.togglePlayPause()
            display: AbstractButton.IconOnly
            Layout.preferredWidth: narrowLayout ? 22 : 24
            Layout.preferredHeight: narrowLayout ? 22 : 24
            ToolTip.visible: hovered
            ToolTip.text: controller && controller.isPlaying ? qsTr("Pause") : qsTr("Play")
        }

        Label {
            color: controller ? controller.colorPanelSubtext : "#CDD4DE"
            text: controller && controller.isPlaying ? qsTr("Playing") : qsTr("Paused")
            font.pixelSize: narrowLayout ? 10 : 11
            visible: !ultraCompact && root.width > 270
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: 4
        height: 3
        radius: 1.5
        color: "#2E4D68"
        z: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.playbackProgress
            radius: parent.radius
            color: "#86D0FF"
        }
    }

    Menu {
        id: quickMenu

        MenuItem {
            text: controller && controller.isPlaying ? qsTr("Pause") : qsTr("Play")
            onTriggered: controller.togglePlayPause()
        }

        MenuItem {
            text: qsTr("Next")
            enabled: controller && controller.canGoNext
            onTriggered: controller.nextTrack()
        }

        MenuItem {
            text: qsTr("Open Player")
            onTriggered: {
                if (controller) {
                    controller.expanded = true
                }
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Build Queue (Range)")
            onTriggered: {
                controller.playbackMode = 0
                controller.buildQueue(false)
            }
        }

        MenuItem {
            text: qsTr("Play Range")
            onTriggered: {
                controller.playbackMode = 0
                controller.buildQueue(true)
            }
        }

        MenuItem {
            text: qsTr("Play Full Surah")
            onTriggered: {
                controller.playbackMode = 1
                controller.buildQueue(true)
            }
        }
    }
}
