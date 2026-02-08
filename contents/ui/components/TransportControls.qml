import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property var controller
    property bool compact: false
    readonly property bool cramped: !compact && width < 340

    spacing: compact || cramped ? 4 : 8

    ToolButton {
        text: qsTr("Previous")
        icon.name: "media-skip-backward"
        enabled: controller && controller.canGoPrevious
        onClicked: controller.previousTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: controller && controller.isPlaying ? qsTr("Pause") : qsTr("Play")
        icon.name: controller && controller.isPlaying ? "media-playback-pause" : "media-playback-start"
        enabled: controller && !controller.isQueueLoading
        onClicked: controller.togglePlayPause()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: qsTr("Next")
        icon.name: "media-skip-forward"
        enabled: controller && controller.canGoNext
        onClicked: controller.nextTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    ToolButton {
        text: qsTr("Bookmark")
        icon.name: "bookmark-new"
        enabled: controller && controller.currentTrack
        onClicked: controller.addBookmark()
        display: AbstractButton.IconOnly
        visible: !compact && !cramped
        ToolTip.visible: hovered
        ToolTip.text: text
    }

    Label {
        visible: !compact && !cramped
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: controller ? controller.timeLabel(controller.playbackPositionMs) + " / " + controller.timeLabel(controller.playbackDurationMs) : ""
        elide: Text.ElideRight
        color: controller ? controller.colorTextSecondary : "#5B6675"
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 1
    }
}
