import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Item {
    id: root

        readonly property real playbackProgress: Models.PlaybackManager.playbackDurationMs > 0
        ? Math.max(0, Math.min(1, Models.PlaybackManager.playbackPositionMs / Models.PlaybackManager.playbackDurationMs))
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
            GradientStop { position: 0.0; color: Models.PlaybackManager.colorPanelStart}
            GradientStop { position: 1.0; color: Models.PlaybackManager.colorPanelEnd}
        }
        border.width: 1
        border.color: Models.PlaybackManager.colorBorder
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        z: 10
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                Models.PlaybackManager.expanded = !Models.PlaybackManager.expanded
            } else if (mouse.button === Qt.MiddleButton) {
                Models.PlaybackManager.togglePlayPause()
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
            color: Models.PlaybackManager.isPlaying ? "#5EDC85" : "#AFC6DA"
        }

        Label {
            Layout.fillWidth: true
            color: Models.PlaybackManager.colorPanelText
            text: Models.PlaybackManager.currentTrackLabel()
            elide: Text.ElideRight
            font.pixelSize: narrowLayout ? 11 : 12
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1
            visible: !ultraCompact
        }

        Item {
            Layout.preferredWidth: narrowLayout ? 24 : 28
            Layout.preferredHeight: narrowLayout ? 24 : 28
            
            Components.CircularProgressBar {
                anchors.fill: parent
                progress: root.playbackProgress
                strokeWidth: 2
                colorBg: Models.PlaybackManager.colorPanelEnd
                colorFg: Models.PlaybackManager.colorAccent
            }
            
            ToolButton {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 2
                flat: true
                icon.name: Models.PlaybackManager.isPlaying ? "media-playback-pause" : "media-playback-start"
                enabled: !Models.PlaybackManager.isQueueLoading
                onClicked: Models.PlaybackManager.togglePlayPause()
                display: AbstractButton.IconOnly
                ToolTip.visible: hovered
                ToolTip.text: Models.PlaybackManager.isPlaying ? qsTr("Pause") : qsTr("Play")
                
                background: Rectangle {
                    color: "transparent"
                    radius: width / 2
                }
            }
        }

        Label {
            color: Models.PlaybackManager.colorPanelSubtext
            text: Models.PlaybackManager.isPlaying ? qsTr("Playing") : qsTr("Paused")
            font.pixelSize: narrowLayout ? 10 : 11
            visible: !ultraCompact && root.width > 270
        }
    }



    Menu {
        id: quickMenu

        MenuItem {
            text: Models.PlaybackManager.isPlaying ? qsTr("Pause") : qsTr("Play")
            onTriggered: Models.PlaybackManager.togglePlayPause()
        }

        MenuItem {
            text: qsTr("Next")
            enabled: Models.PlaybackManager.canGoNext
            onTriggered: Models.PlaybackManager.nextTrack()
        }

        MenuItem {
            text: qsTr("Open Player")
            onTriggered: Models.PlaybackManager.expanded = true
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Build Queue (Range)")
            onTriggered: {
                Models.PlaybackManager.playbackMode = 0
                Models.PlaybackManager.buildQueue(false)
            }
        }

        MenuItem {
            text: qsTr("Play Range")
            onTriggered: {
                Models.PlaybackManager.playbackMode = 0
                Models.PlaybackManager.buildQueue(true)
            }
        }

        MenuItem {
            text: qsTr("Play Full Surah")
            onTriggered: {
                Models.PlaybackManager.playbackMode = 1
                Models.PlaybackManager.buildQueue(true)
            }
        }
    }
}
