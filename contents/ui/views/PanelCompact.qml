import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "../components" as Components

Item {
    id: root

    readonly property real playbackProgress: Models.PlaybackManager.playbackDurationMs > 0
        ? Math.max(0, Math.min(1, Models.PlaybackManager.playbackPositionMs / Models.PlaybackManager.playbackDurationMs))
        : 0
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool narrowLayout: width < 230
    readonly property bool ultraCompact: width < 165 || verticalPanel
    readonly property bool statusIsLoading: Models.PlaybackManager.isQueueLoading
    readonly property bool statusIsError: Models.PlaybackManager.hasErrorStatus
    readonly property bool panelHovered: expandArea.containsMouse || playPauseBtn.hovered || contextArea.containsMouse
    readonly property bool panelPressed: expandArea.pressed || playPauseBtn.down

    Layout.minimumWidth: verticalPanel ? 44 : 180
    Layout.preferredWidth: verticalPanel ? 44 : 300
    Layout.maximumWidth: verticalPanel ? 64 : 500
    Layout.minimumHeight: verticalPanel ? 120 : 44
    Layout.preferredHeight: verticalPanel ? 180 : (narrowLayout ? 58 : 54)
    implicitWidth: verticalPanel ? 44 : 300
    implicitHeight: verticalPanel ? 180 : (narrowLayout ? 58 : 54)
    clip: true

    // Glassmorphic background
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(Models.PlaybackManager.colorPanelStart.r, Models.PlaybackManager.colorPanelStart.g, Models.PlaybackManager.colorPanelStart.b, 0.75)
        border.width: 1
        border.color: root.statusIsError
            ? Models.PlaybackManager.colorNegative
            : (root.panelHovered 
                ? Models.PlaybackManager.colorAccent 
                : Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.12))

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Models.PlaybackManager.colorTextPrimary
            opacity: root.panelPressed ? 0.08 : (root.panelHovered ? 0.03 : 0)

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
        anchors.rightMargin: ultraCompact ? 0 : (narrowLayout ? 34 : 38)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        z: 1
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                Models.PlaybackManager.expanded = !Models.PlaybackManager.expanded
            } else if (mouse.button === Qt.MiddleButton) {
                Models.PlaybackManager.togglePlayPause()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: narrowLayout ? 6 : 8
        z: 2

        // Glowing Status Indicator Bulb
        Rectangle {
            id: statusBulb
            visible: !ultraCompact
            width: narrowLayout ? 6 : 8
            height: width
            radius: width / 2
            color: root.statusIsError
                ? Models.PlaybackManager.colorNegative
                : (root.statusIsLoading
                    ? Models.PlaybackManager.colorAccent
                    : (Models.PlaybackManager.isPlaying ? Models.PlaybackManager.colorPositive : Models.PlaybackManager.colorNeutral))

            // Backdrop Glow
            Rectangle {
                id: glowBulb
                anchors.centerIn: parent
                width: parent.width * 2.2
                height: width
                radius: width / 2
                color: statusBulb.color
                opacity: (root.statusIsError || Models.PlaybackManager.isPlaying || root.statusIsLoading) ? 0.3 : 0.0
                z: -1

                SequentialAnimation on opacity {
                    running: Models.PlaybackManager.isPlaying || root.statusIsLoading
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.15; to: 0.65; duration: root.statusIsLoading ? 400 : 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.65; to: 0.15; duration: root.statusIsLoading ? 400 : 1000; easing.type: Easing.InOutQuad }
                }

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }
            }

            Behavior on color {
                ColorAnimation { duration: 180 }
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
                font.weight: Font.DemiBold
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
            Layout.preferredWidth: narrowLayout ? 26 : 30
            Layout.preferredHeight: narrowLayout ? 26 : 30
            Layout.alignment: Qt.AlignVCenter

            Components.CircularProgressBar {
                anchors.fill: parent
                progress: root.playbackProgress
                strokeWidth: 2
                colorBg: Qt.rgba(Models.PlaybackManager.colorPanelEnd.r, Models.PlaybackManager.colorPanelEnd.g, Models.PlaybackManager.colorPanelEnd.b, 0.3)
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
                    color: playPauseBtn.down ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.15) :
                           (playPauseBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.08) : "transparent")
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
