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
    readonly property bool statusIsLoading: Models.PlaybackManager.isQueueLoading
    readonly property bool statusIsError: Models.PlaybackManager.hasErrorStatus
    readonly property bool panelHovered: expandArea.containsMouse || playPauseBtn.hovered || contextArea.containsMouse
    readonly property bool panelPressed: expandArea.pressed || playPauseBtn.down

    Layout.minimumWidth: 180
    Layout.preferredWidth: 300
    Layout.maximumWidth: 500
    implicitWidth: 300
    implicitHeight: narrowLayout ? 58 : 54
    clip: true

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: Models.PlaybackManager.colorPanelStart}
            GradientStop { position: 1.0; color: Models.PlaybackManager.colorPanelEnd}
        }
        border.width: 1
        border.color: root.statusIsError
            ? Models.PlaybackManager.colorNegative
            : (root.panelHovered ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorBorder)
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Models.PlaybackManager.colorTextPrimary
            opacity: root.panelPressed ? 0.1 : (root.panelHovered ? 0.05 : 0)
            
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
    }

    MouseArea {
        id: contextArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        z: 3
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                quickMenu.popup()
            }
        }
    }

    MouseArea {
        id: expandArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: narrowLayout ? 34 : 38
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        z: 1
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                Models.PlaybackManager.expanded = !Models.PlaybackManager.expanded
            } else if (mouse.button === Qt.MiddleButton && Models.PlaybackManager.middleClickToggleEnabled) {
                Models.PlaybackManager.togglePlayPause()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: narrowLayout ? 6 : 8
        z: 2

        Rectangle {
            width: narrowLayout ? 6 : 8
            height: narrowLayout ? 6 : 8
            radius: width / 2
            color: root.statusIsError
                ? Models.PlaybackManager.colorNegative
                : (root.statusIsLoading
                    ? Models.PlaybackManager.colorAccent
                    : (Models.PlaybackManager.isPlaying ? Models.PlaybackManager.colorPositive : Models.PlaybackManager.colorNeutral))
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            visible: !ultraCompact

            Label {
                Layout.fillWidth: true
                color: Models.PlaybackManager.colorPanelText
                text: Models.PlaybackManager.currentTrackLabel()
                elide: Text.ElideRight
                font.pixelSize: narrowLayout ? 11 : 12
                maximumLineCount: 1
            }

            Label {
                Layout.fillWidth: true
                color: root.statusIsError ? Models.PlaybackManager.colorNegative : Models.PlaybackManager.colorPanelSubtext
                text: Models.PlaybackManager.selectedReciter ? Models.PlaybackManager.selectedReciter.name : qsTr("Select reciter")
                elide: Text.ElideRight
                font.pixelSize: 10
                maximumLineCount: 1
            }
        }

        Item {
            id: controlWrap
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
                id: playPauseBtn
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
                Accessible.name: ToolTip.text
                
                background: Rectangle {
                    color: playPauseBtn.down ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.2) :
                           (playPauseBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.1) : "transparent")
                    radius: width / 2
                    
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }
            }
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
                Models.PlaybackManager.requestBuildQueue({ autoPlay: false })
            }
        }

        MenuItem {
            text: qsTr("Play Range")
            onTriggered: {
                Models.PlaybackManager.playbackMode = 0
                Models.PlaybackManager.requestBuildQueue({ autoPlay: true })
            }
        }

        MenuItem {
            text: qsTr("Play Full Surah")
            onTriggered: {
                Models.PlaybackManager.playbackMode = 1
                Models.PlaybackManager.requestBuildQueue({ autoPlay: true })
            }
        }
    }
}
