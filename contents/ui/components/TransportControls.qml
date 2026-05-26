import QtQuick
import org.kde.kirigami as Kirigami
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property bool compact: false
    readonly property bool cramped: !compact && width < 340

    spacing: compact || cramped ? 4 : 10

    ToolButton {
        id: prevButton
        text: qsTr("Previous")
        icon.name: "media-skip-backward"
        enabled: Models.PlaybackManager.canGoPrevious
        onClicked: Models.PlaybackManager.previousTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text

        background: Rectangle {
            implicitWidth: Math.round(36 * (Models.PlaybackManager.uiScale || 1.0))
            implicitHeight: implicitWidth
            radius: width / 2
            color: prevButton.pressed ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.15) :
                   (prevButton.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.08) : "transparent")
            scale: prevButton.pressed ? 0.92 : (prevButton.hovered ? 1.08 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        contentItem: Kirigami.Icon {
            source: prevButton.icon.name || ""
            anchors.centerIn: parent
            width: Math.round(18 * (Models.PlaybackManager.uiScale || 1.0))
            height: width
            opacity: prevButton.enabled ? 1.0 : 0.35
            color: Models.PlaybackManager.colorTextPrimary
        }
    }

    ToolButton {
        id: playButton
        text: Models.PlaybackManager.isPlaying ? qsTr("Pause") : qsTr("Play")
        icon.name: Models.PlaybackManager.isPlaying ? "media-playback-pause" : "media-playback-start"
        enabled: !Models.PlaybackManager.isQueueLoading
        onClicked: Models.PlaybackManager.togglePlayPause()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text

        background: Item {
            implicitWidth: Math.round(46 * (Models.PlaybackManager.uiScale || 1.0))
            implicitHeight: implicitWidth

            // Glowing border/shadow effect
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: width / 2
                color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.25)
                visible: playButton.hovered
                scale: playButton.pressed ? 0.92 : 1.08

                Behavior on scale { NumberAnimation { duration: 120 } }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: playButton.enabled ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorSurfaceMuted
                scale: playButton.pressed ? 0.94 : (playButton.hovered ? 1.06 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        contentItem: Kirigami.Icon {
            source: playButton.icon.name || ""
            anchors.centerIn: parent
            width: Math.round(20 * (Models.PlaybackManager.uiScale || 1.0))
            height: width
            opacity: playButton.enabled ? 1.0 : 0.4
            color: "#FFFFFF"
        }
    }

    ToolButton {
        id: nextButton
        text: qsTr("Next")
        icon.name: "media-skip-forward"
        enabled: Models.PlaybackManager.canGoNext
        onClicked: Models.PlaybackManager.nextTrack()
        display: AbstractButton.IconOnly
        ToolTip.visible: hovered
        ToolTip.text: text

        background: Rectangle {
            implicitWidth: Math.round(36 * (Models.PlaybackManager.uiScale || 1.0))
            implicitHeight: implicitWidth
            radius: width / 2
            color: nextButton.pressed ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.15) :
                   (nextButton.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.08) : "transparent")
            scale: nextButton.pressed ? 0.92 : (nextButton.hovered ? 1.08 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        contentItem: Kirigami.Icon {
            source: nextButton.icon.name || ""
            anchors.centerIn: parent
            width: Math.round(18 * (Models.PlaybackManager.uiScale || 1.0))
            height: width
            opacity: nextButton.enabled ? 1.0 : 0.35
            color: Models.PlaybackManager.colorTextPrimary
        }
    }

    ToolButton {
        id: bookmarkButton
        text: qsTr("Bookmark")
        icon.name: "bookmark-new"
        enabled: Models.PlaybackManager.currentTrack
        onClicked: Models.PlaybackManager.addBookmark()
        display: AbstractButton.IconOnly
        visible: !compact && !cramped
        ToolTip.visible: hovered
        ToolTip.text: text

        background: Rectangle {
            implicitWidth: Math.round(36 * (Models.PlaybackManager.uiScale || 1.0))
            implicitHeight: implicitWidth
            radius: width / 2
            color: bookmarkButton.pressed ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.15) :
                   (bookmarkButton.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.08) : "transparent")
            scale: bookmarkButton.pressed ? 0.92 : (bookmarkButton.hovered ? 1.08 : 1.0)

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        contentItem: Kirigami.Icon {
            source: bookmarkButton.icon.name || ""
            anchors.centerIn: parent
            width: Math.round(18 * (Models.PlaybackManager.uiScale || 1.0))
            height: width
            opacity: bookmarkButton.enabled ? 1.0 : 0.35
            color: Models.PlaybackManager.colorTextPrimary
        }
    }

    Label {
        visible: !compact && !cramped
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackPositionMs) + " / " + Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackDurationMs)
        elide: Text.ElideRight
        color: Models.PlaybackManager.colorTextSecondary
        font.pixelSize: Math.round(12 * (Models.PlaybackManager.uiScale || 1.0))
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 1
    }
}
