import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../components" as Components

Item {
    id: root

    readonly property real scaleFactor: Models.PlaybackManager.uiScale
    readonly property bool narrowLayout: width < 430
    readonly property bool statusIsError: Models.PlaybackManager.hasErrorStatus
    readonly property bool statusIsLoading: Models.PlaybackManager.isQueueLoading
    readonly property bool showRetryAction: statusIsError && !statusIsLoading
    readonly property bool showStatusBanner:
        statusIsLoading
        || (Models.PlaybackManager.statusText
            && Models.PlaybackManager.statusText.length > 0
            && Models.PlaybackManager.statusText !== qsTr("Ready"))
    property bool showDelayedSpinner: false
    property bool showSlowLoadingHint: false

    implicitWidth: 540
    implicitHeight: 760

    onStatusIsLoadingChanged: {
        if (statusIsLoading) {
            showDelayedSpinner = false
            showSlowLoadingHint = false
            spinnerDelayTimer.restart()
            slowLoadingTimer.restart()
        } else {
            spinnerDelayTimer.stop()
            slowLoadingTimer.stop()
            showDelayedSpinner = false
            showSlowLoadingHint = false
        }
    }

    Timer {
        id: spinnerDelayTimer
        interval: 300
        repeat: false
        onTriggered: root.showDelayedSpinner = root.statusIsLoading
    }

    Timer {
        id: slowLoadingTimer
        interval: 1200
        repeat: false
        onTriggered: root.showSlowLoadingHint = root.statusIsLoading
    }

    // ── Background ──────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0.0; color: Models.PlaybackManager.colorBgStart }
            GradientStop { position: 1.0; color: Models.PlaybackManager.colorBgEnd }
        }
        border.width: 1
        border.color: Models.PlaybackManager.colorBorder
    }

    // ── Main Content ────────────────────────────────────────────────────
    ScrollView {
        id: scrollArea
        anchors.fill: parent
        anchors.margins: 14
        clip: true
        contentWidth: availableWidth
        contentHeight: contentColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentColumn
            width: scrollArea.availableWidth
            spacing: 14

            // ════════════════════════════════════════════════════════════
            //  NOW PLAYING CARD
            // ════════════════════════════════════════════════════════════
            Components.SurfaceCard {
                Layout.fillWidth: true
                implicitHeight: nowPlayingLayout.implicitHeight + 24

                // Add a subtle gradient background to the now playing card
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.08) }
                        GradientStop { position: 0.5; color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.02) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    border.width: 1
                    border.color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.12)
                    z: -1
                }

                ColumnLayout {
                    id: nowPlayingLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Quran Player")
                            font.bold: true
                            font.pixelSize: Math.round(24 * root.scaleFactor)
                            color: Models.PlaybackManager.colorTextPrimary
                        }

                        Rectangle {
                            visible: Models.PlaybackManager.queueModel
                                     && Models.PlaybackManager.queueModel.count > 0
                            implicitWidth: queuePositionText.implicitWidth + 16
                            implicitHeight: 26
                            radius: 13
                            color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.14)
                            border.width: 1
                            border.color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.35)

                            Label {
                                id: queuePositionText
                                anchors.centerIn: parent
                                text: Models.PlaybackManager.queuePositionLabel()
                                color: Models.PlaybackManager.colorTextPrimary
                                font.pixelSize: Math.round(11 * root.scaleFactor)
                                font.bold: true
                            }
                        }

                        Kirigami.Icon {
                            source: "media-playback-start"
                            implicitWidth: 24
                            implicitHeight: 24
                            color: Models.PlaybackManager.colorAccent
                            opacity: Models.PlaybackManager.isPlaying ? 1.0 : 0.5

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                        }
                    }

                    // Track Info Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Current track
                        Label {
                            Layout.fillWidth: true
                            text: Models.PlaybackManager.currentTrackLabel()
                            color: Models.PlaybackManager.colorTextPrimary
                            elide: Text.ElideRight
                            font.bold: true
                            font.pixelSize: Math.round(18 * root.scaleFactor)

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: parent; property: "opacity"; to: 0.4; duration: 100 }
                                    NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 200 }
                                }
                            }
                        }

                        // Reciter name
                        Label {
                            Layout.fillWidth: true
                            text: Models.PlaybackManager.selectedReciter
                                  ? Models.PlaybackManager.selectedReciter.name
                                  : qsTr("Select reciter")
                            color: Models.PlaybackManager.colorTextSecondary
                            elide: Text.ElideRight
                            font.pixelSize: Math.round(14 * root.scaleFactor)
                        }
                    }

                    // Ayah Text Display
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: ayahTextLabel.implicitHeight + 28
                        color: Models.PlaybackManager.colorSurfaceMuted
                        radius: 12
                        border.width: 1
                        border.color: Models.PlaybackManager.colorBorder
                        visible: Models.PlaybackManager.currentAyahText.length > 0

                        Label {
                            id: ayahTextLabel
                            anchors.fill: parent
                            anchors.margins: 14
                            text: Models.PlaybackManager.currentAyahText
                            color: Models.PlaybackManager.colorTextPrimary
                            font.pixelSize: Math.round(24 * root.scaleFactor)
                            font.family: "Noto Naskh Arabic, Amiri, Scheherazade New, serif"
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            LayoutMirroring.enabled: true // Enable RTL for Arabic
                            LayoutMirroring.childrenInherit: true

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: parent; property: "opacity"; to: 0; duration: 150 }
                                    NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 300 }
                                }
                            }
                        }
                    }

                    // ── Progress & Time ─────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Item {
                            id: seekSliderWrap
                            Layout.fillWidth: true
                            implicitHeight: seekSlider.implicitHeight + 22
                            property real hoverRatio: seekSlider.position
                            property real hoverX: 0
                            readonly property int seekBasisMs: Models.PlaybackManager.playbackDurationMs > 0
                                ? Models.PlaybackManager.playbackDurationMs
                                : Math.max(3600000, Models.PlaybackManager.playbackPositionMs + 300000)
                            property real dragValue: Models.PlaybackManager.playbackPositionMs
                            property real dragRatio: seekSlider.position

                            function updateHover(mouseX) {
                                if (!seekSlider.enabled || seekSlider.availableWidth <= 0) {
                                    return
                                }
                                var left = seekSlider.leftPadding
                                var right = left + seekSlider.availableWidth
                                var clampedX = Math.max(left, Math.min(right, mouseX))
                                hoverX = clampedX
                                hoverRatio = Math.max(0, Math.min(1, (clampedX - left) / seekSlider.availableWidth))
                            }

                            function setDragFromX(mouseX, commit) {
                                if (!seekSlider.enabled || seekSlider.availableWidth <= 0) {
                                    return
                                }
                                var left = seekSlider.leftPadding
                                var right = left + seekSlider.availableWidth
                                var clampedX = Math.max(left, Math.min(right, mouseX))
                                hoverX = clampedX
                                hoverRatio = Math.max(0, Math.min(1, (clampedX - left) / seekSlider.availableWidth))
                                dragRatio = hoverRatio
                                dragValue = Math.round(dragRatio * seekBasisMs)
                                if (commit) {
                                    Models.PlaybackManager.requestSeek(dragValue)
                                }
                            }

                            Slider {
                                id: seekSlider
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                from: 0
                                to: Math.max(1, seekSliderWrap.seekBasisMs)
                                value: seekInputArea.pressed
                                    ? seekSliderWrap.dragValue
                                    : Models.PlaybackManager.playbackPositionMs
                                enabled: Models.PlaybackManager.currentTrack
                                onMoved: Models.PlaybackManager.requestSeek(value)

                                background: Rectangle {
                                    x: seekSlider.leftPadding
                                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                    width: seekSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: Models.PlaybackManager.colorBorder

                                    Rectangle {
                                        width: seekSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: Models.PlaybackManager.colorAccent

                                        Behavior on width {
                                            enabled: !seekSlider.pressed
                                            NumberAnimation { duration: 120 }
                                        }
                                    }
                                }

                                handle: Rectangle {
                                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                    width: seekSlider.pressed ? 14 : (seekSlider.hovered ? 12 : 8)
                                    height: width
                                    radius: width / 2
                                    color: Models.PlaybackManager.colorAccent
                                    border.color: Qt.lighter(Models.PlaybackManager.colorAccent, 1.25)
                                    border.width: 1

                                    Behavior on width {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                                    }
                                }
                            }

                            MouseArea {
                                id: seekInputArea
                                anchors.fill: seekSlider
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true
                                onEntered: {
                                    seekSliderWrap.updateHover(mouseX)
                                }
                                onPressed: function(mouse) {
                                    seekSliderWrap.setDragFromX(mouse.x, false)
                                }
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        seekSliderWrap.setDragFromX(mouse.x, false)
                                    } else {
                                        seekSliderWrap.updateHover(mouse.x)
                                    }
                                }
                                onReleased: function(mouse) {
                                    seekSliderWrap.setDragFromX(mouse.x, true)
                                }
                                onCanceled: {
                                    seekSliderWrap.dragValue = Models.PlaybackManager.playbackPositionMs
                                    seekSliderWrap.dragRatio = seekSlider.position
                                }
                                onExited: {
                                    if (!pressed) {
                                        seekSliderWrap.hoverRatio = seekSlider.position
                                    }
                                }
                            }

                            Rectangle {
                                id: seekPreviewBubble
                                visible: seekSlider.enabled && (seekInputArea.containsMouse || seekInputArea.pressed)
                                y: seekSlider.y - height - 6
                                height: 20
                                width: bubbleLabel.implicitWidth + 10
                                radius: 6
                                color: Qt.rgba(0, 0, 0, 0.75)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.18)
                                readonly property real previewRatio: seekInputArea.pressed ? seekSliderWrap.dragRatio : seekSliderWrap.hoverRatio
                                readonly property int previewMs: Math.round(previewRatio * seekSliderWrap.seekBasisMs)
                                x: {
                                    var centerX = seekSlider.leftPadding + (previewRatio * seekSlider.availableWidth)
                                    return Math.max(0, Math.min(seekSliderWrap.width - width, centerX - width / 2))
                                }

                                Label {
                                    id: bubbleLabel
                                    anchors.centerIn: parent
                                    text: Models.PlaybackManager.timeLabel(seekPreviewBubble.previewMs)
                                    color: "#ffffff"
                                    font.pixelSize: 10
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackPositionMs)
                                color: Models.PlaybackManager.colorTextSecondary
                                font.pixelSize: Math.round(11 * root.scaleFactor)
                                font.family: "monospace"
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: Models.PlaybackManager.playbackDurationMs > 0
                                    ? Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackDurationMs)
                                    : ("~" + Models.PlaybackManager.timeLabel(seekSliderWrap.seekBasisMs))
                                color: Models.PlaybackManager.colorTextSecondary
                                font.pixelSize: Math.round(11 * root.scaleFactor)
                                font.family: "monospace"
                            }
                        }
                    }

                    // Transport controls
                    Components.TransportControls {
                        Layout.fillWidth: true
                        compact: root.narrowLayout
                    }

                    // Status banner with improved visual design
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: statusLayout.implicitHeight + 12
                        visible: root.showStatusBanner
                        Accessible.name: Models.PlaybackManager.statusText
                        radius: 6
                        color: root.statusIsError
                               ? Models.PlaybackManager.colorErrorBg
                               : (root.statusIsLoading ? Models.PlaybackManager.colorSurfaceMuted : Models.PlaybackManager.colorInfoBg)
                        border.width: 1
                        border.color: root.statusIsError
                                      ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.35)
                                      : Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.35)

                        RowLayout {
                            id: statusLayout
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            BusyIndicator {
                                running: root.statusIsLoading && root.showDelayedSpinner
                                visible: running
                                implicitWidth: 16
                                implicitHeight: 16
                            }

                            Kirigami.Icon {
                                source: root.statusIsError ? "dialog-warning" : "dialog-information"
                                visible: !root.statusIsLoading
                                implicitWidth: 16
                                implicitHeight: 16
                                color: root.statusIsError ? Models.PlaybackManager.colorNegative : Models.PlaybackManager.colorAccent
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.statusIsLoading && root.showSlowLoadingHint
                                    ? qsTr("Still working, preparing results...")
                                    : Models.PlaybackManager.statusText
                                color: root.statusIsError
                                       ? Models.PlaybackManager.colorNegative
                                       : Models.PlaybackManager.colorTextPrimary
                                wrapMode: Text.WordWrap
                                font.pixelSize: Math.round(11 * root.scaleFactor)
                            }

                            Rectangle {
                                visible: root.statusIsLoading && root.showSlowLoadingHint
                                implicitWidth: 56
                                implicitHeight: 8
                                radius: 4
                                color: Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.2)
                            }

                            Button {
                                visible: root.showRetryAction
                                text: qsTr("Retry")
                                onClicked: Models.PlaybackManager.requestRetryLastAction()
                            }

                            Button {
                                visible: root.showRetryAction
                                text: qsTr("Fallback to curated")
                                onClicked: Models.PlaybackManager.requestFallbackToCurated()
                            }
                        }
                    }
                }
            }

            // ════════════════════════════════════════════════════════════
            //  TAB BAR CARD
            // ════════════════════════════════════════════════════════════
            Components.SurfaceCard {
                Layout.fillWidth: true
                implicitHeight: sectionTabs.implicitHeight + 10

                TabBar {
                    id: sectionTabs
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: root.narrowLayout ? 6 : 8
                    background: Item {}

                    Components.StyledTabButton {
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Player")
                        icon.name: "media-playback-start"
                        narrowLayout: root.narrowLayout
                        scaleFactor: root.scaleFactor
                    }

                    Components.StyledTabButton {
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Library")
                        icon.name: "view-list-details"
                        narrowLayout: root.narrowLayout
                        scaleFactor: root.scaleFactor
                    }

                    Components.StyledTabButton {
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Settings")
                        icon.name: "settings-configure"
                        narrowLayout: root.narrowLayout
                        scaleFactor: root.scaleFactor
                    }
                }
            }

            // ════════════════════════════════════════════════════════════
            //  SWIPE PAGES
            // ════════════════════════════════════════════════════════════
            SwipeView {
                id: sectionStack
                Layout.fillWidth: true
                implicitHeight: sectionStack.currentItem
                               ? sectionStack.currentItem.implicitHeight : 0
                Layout.preferredHeight: implicitHeight
                currentIndex: sectionTabs.currentIndex
                onCurrentIndexChanged: sectionTabs.currentIndex = currentIndex

                PlayerPage {
                    id: playerPage
                    narrowLayout: root.narrowLayout
                    scaleFactor: root.scaleFactor
                }

                LibraryPage {
                    id: libraryPage
                    narrowLayout: root.narrowLayout
                    scaleFactor: root.scaleFactor
                }

                SettingsPage {
                    id: settingsPage
                    narrowLayout: root.narrowLayout
                    scaleFactor: root.scaleFactor
                }
            }
        }
    }
}
