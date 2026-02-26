import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property bool compact: false
    readonly property bool cramped: !compact && width < 340

    spacing: compact || cramped ? 4 : 8

    ToolButton {
        text: qsTr("Previous")
        icon.name: "media-skip-backward"
        enabled: Models.PlaybackManager.canGoPrevious
        onClicked: Models.PlaybackManager.previousTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: Models.PlaybackManager.isPlaying ? qsTr("Pause") : qsTr("Play")
        icon.name: Models.PlaybackManager.isPlaying ? "media-playback-pause" : "media-playback-start"
        enabled: !Models.PlaybackManager.isQueueLoading
        onClicked: Models.PlaybackManager.togglePlayPause()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: qsTr("Next")
        icon.name: "media-skip-forward"
        enabled: Models.PlaybackManager.canGoNext
        onClicked: Models.PlaybackManager.nextTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: qsTr("Bookmark")
        icon.name: "bookmark-new"
        enabled: Models.PlaybackManager.currentTrack
        onClicked: Models.PlaybackManager.addBookmark()
        display: AbstractButton.IconOnly
        visible: !compact && !cramped
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    Label {
        visible: !compact && !cramped
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackPositionMs) + " / " + Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackDurationMs)
        elide: Text.ElideRight
        color: Models.PlaybackManager.colorTextSecondary
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 1
    }
}
