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
                        GradientStop { position: 0.0; color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.1) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
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
                        
                        // Add an icon or small logo here later if needed
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
                        implicitHeight: ayahTextLabel.implicitHeight + 24
                        color: "transparent"
                        visible: Models.PlaybackManager.currentAyahText.length > 0
                        
                        Label {
                            id: ayahTextLabel
                            anchors.fill: parent
                            anchors.margins: 12
                            text: Models.PlaybackManager.currentAyahText
                            color: Models.PlaybackManager.colorTextPrimary
                            font.pixelSize: Math.round(24 * root.scaleFactor)
                            font.family: "Noto Naskh Arabic, KFGQPC Uthman Taha Naskh, Amiri, Scheherazade New, serif"
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
                                dragValue = Math.round(dragRatio * Models.PlaybackManager.playbackDurationMs)
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
                                to: Math.max(1, Models.PlaybackManager.playbackDurationMs)
                                value: seekInputArea.pressed
                                    ? seekSliderWrap.dragValue
                                    : Models.PlaybackManager.playbackPositionMs
                                enabled: Models.PlaybackManager.currentTrack && Models.PlaybackManager.playerSeekable
                                onMoved: Models.PlaybackManager.requestSeek(value)

                                background: Rectangle {
                                    x: seekSlider.leftPadding
                                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                    width: seekSlider.availableWidth
                                    height: 6
                                    radius: 3
                                    color: Models.PlaybackManager.colorBorder

                                    Rectangle {
                                        width: seekSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 3
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
                                    width: seekSlider.pressed ? 18 : (seekSlider.hovered ? 16 : 14)
                                    height: width
                                    radius: width / 2
                                    color: Models.PlaybackManager.colorAccent
                                    border.color: Qt.lighter(Models.PlaybackManager.colorAccent, 1.3)
                                    border.width: 1

                                    Behavior on width {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
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
                                readonly property int previewMs: Math.round(previewRatio * Models.PlaybackManager.playbackDurationMs)
                                x: {
                                    var centerX = seekSlider.leftPadding + (previewRatio * seekSlider.availableWidth)
                                    return Math.max(0, Math.min(seekSliderWrap.width - width, centerX - width / 2))
                                }

                                Label {
                                    id: bubbleLabel
                                    anchors.centerIn: parent
                                    text: Models.PlaybackManager.timeLabel(seekPreviewBubble.previewMs)
                                        + " / "
                                        + Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackDurationMs)
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
                                text: Models.PlaybackManager.timeLabel(Models.PlaybackManager.playbackDurationMs)
                                color: Models.PlaybackManager.colorTextSecondary
                                font.pixelSize: Math.round(11 * root.scaleFactor)
                                font.family: "monospace"
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: Models.PlaybackManager.currentTrack && !Models.PlaybackManager.playerSeekable
                            text: qsTr("Current stream does not support seeking")
                            color: Models.PlaybackManager.colorTextSecondary
                            font.pixelSize: Math.round(10 * root.scaleFactor)
                            wrapMode: Text.WordWrap
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

                // ──── Player Page ───────────────────────────────────
                ColumnLayout {
                    id: playerPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: rangeCard.implicitHeight
                                  + advancedCard.implicitHeight
                                  + queueCard.implicitHeight
                                  + (spacing * 2)

                    // Playback Range
                    Components.SurfaceCard {
                        id: rangeCard
                        Layout.fillWidth: true
                        implicitHeight: rangeCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: rangeCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Label {
                                text: qsTr("Playback Range")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            Components.RangePicker {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Advanced Controls
                    Components.SurfaceCard {
                        id: advancedCard
                        Layout.fillWidth: true
                        implicitHeight: advancedCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: advancedCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Label {
                                text: qsTr("Advanced Controls")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            Components.ProControls {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Queue
                    Components.SurfaceCard {
                        id: queueCard
                        Layout.fillWidth: true
                        implicitHeight: queueCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: queueCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Label {
                                text: qsTr("Queue")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            Components.QueueList {
                                Layout.fillWidth: true
                                Layout.preferredHeight:
                                    Models.PlaybackManager.queueModel
                                    && Models.PlaybackManager.queueModel.count > 0
                                    ? Math.min(200, Models.PlaybackManager.queueModel.count * 48) : 0
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Queue is empty")
                                visible: !Models.PlaybackManager.queueModel
                                         || Models.PlaybackManager.queueModel.count === 0
                                color: Models.PlaybackManager.colorTextSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // ──── Library Page ───────────────────────────────────
                ColumnLayout {
                    id: libraryPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: presetsCard.implicitHeight
                                  + bookmarksCard.implicitHeight + spacing

                    // Presets
                    Components.SurfaceCard {
                        id: presetsCard
                        Layout.fillWidth: true
                        implicitHeight: presetsCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: presetsCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Presets")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: root.narrowLayout ? 1 : 2
                                columnSpacing: 8
                                rowSpacing: 8

                                TextField {
                                    id: presetLabel
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Preset name")
                                }

                                Button {
                                    text: qsTr("Save")
                                    Layout.fillWidth: root.narrowLayout
                                    onClicked: {
                                        Models.PlaybackManager.saveCurrentPreset(presetLabel.text)
                                        presetLabel.text = ""
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight:
                                    Models.PlaybackManager.presets
                                    && Models.PlaybackManager.presets.length > 0
                                    ? Math.min(170, contentHeight) : 0
                                clip: true
                                model: Models.PlaybackManager.presets

                                delegate: RowLayout {
                                    width: ListView.view.width
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: Models.PlaybackManager.colorTextPrimary
                                    }

                                    ToolButton {
                                        icon.name: "media-playback-start"
                                        display: AbstractButton.IconOnly
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Apply preset")
                                        Accessible.name: ToolTip.text
                                        onClicked: Models.PlaybackManager.applyPreset(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
                                        display: AbstractButton.IconOnly
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Delete")
                                        Accessible.name: ToolTip.text
                                        onClicked: Models.PlaybackManager.removePreset(modelData.id)
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("No presets yet")
                                visible: !Models.PlaybackManager.presets
                                         || Models.PlaybackManager.presets.length === 0
                                color: Models.PlaybackManager.colorTextSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Bookmarks
                    Components.SurfaceCard {
                        id: bookmarksCard
                        Layout.fillWidth: true
                        implicitHeight: bookmarksCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: bookmarksCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Bookmarks")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight:
                                    Models.PlaybackManager.bookmarks
                                    && Models.PlaybackManager.bookmarks.length > 0
                                    ? Math.min(190, contentHeight) : 0
                                clip: true
                                model: Models.PlaybackManager.bookmarks

                                delegate: RowLayout {
                                    width: ListView.view.width
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: Models.PlaybackManager.colorTextPrimary
                                    }

                                    ToolButton {
                                        icon.name: "go-jump"
                                        display: AbstractButton.IconOnly
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Jump to bookmark")
                                        Accessible.name: ToolTip.text
                                        onClicked: Models.PlaybackManager.jumpToBookmark(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
                                        display: AbstractButton.IconOnly
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Delete")
                                        Accessible.name: ToolTip.text
                                        onClicked: Models.PlaybackManager.removeBookmark(modelData.id)
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("No bookmarks yet")
                                visible: !Models.PlaybackManager.bookmarks
                                         || Models.PlaybackManager.bookmarks.length === 0
                                color: Models.PlaybackManager.colorTextSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // ──── Settings Page ─────────────────────────────────
                ColumnLayout {
                    id: settingsPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: comfortCard.implicitHeight
                                  + analyticsCard.implicitHeight
                                  + statusCard.implicitHeight
                                  + (spacing * 2)

                    // Comfort (UI size)
                    Components.SurfaceCard {
                        id: comfortCard
                        Layout.fillWidth: true
                        implicitHeight: comfortCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: comfortCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Comfort")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: qsTr("UI size")
                                    color: Models.PlaybackManager.colorTextPrimary
                                    Layout.preferredWidth: root.narrowLayout ? 56 : 70
                                }

                                Slider {
                                    Layout.fillWidth: true
                                    from: 0.90
                                    to: 1.15
                                    stepSize: 0.05
                                    value: Models.PlaybackManager.uiScale
                                    onMoved: Models.PlaybackManager.setUiScale(value)
                                }

                                Label {
                                    text: Math.round(Models.PlaybackManager.uiScale * 100) + "%"
                                    color: Models.PlaybackManager.colorTextSecondary
                                    Layout.preferredWidth: root.narrowLayout ? 42 : 48
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            CheckBox {
                                text: qsTr("Middle-click toggles play/pause in panel")
                                checked: Models.PlaybackManager.middleClickToggleEnabled
                                onToggled: Models.PlaybackManager.middleClickToggleEnabled = checked
                                palette.windowText: Models.PlaybackManager.colorTextPrimary
                            }
                        }
                    }

                    // Analytics
                    Components.SurfaceCard {
                        id: analyticsCard
                        Layout.fillWidth: true
                        implicitHeight: analyticsCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: analyticsCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            CheckBox {
                                text: qsTr("Enable anonymous analytics")
                                checked: Models.PlaybackManager.telemetryEnabled
                                enabled: Models.PlaybackManager.telemetryAvailable
                                onToggled: {
                                    if (enabled) {
                                        Models.PlaybackManager.telemetryEnabled = checked
                                    }
                                }
                                palette.windowText: Models.PlaybackManager.colorTextPrimary
                            }

                            Label {
                                Layout.fillWidth: true
                                text: Models.PlaybackManager.telemetryAvailable
                                    ? qsTr("Opt-in only. No analytics are sent unless you enable this.")
                                    : qsTr("Analytics is currently unavailable in this build.")
                                color: Models.PlaybackManager.colorTextSecondary
                                wrapMode: Text.WordWrap
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Status
                    Components.SurfaceCard {
                        id: statusCard
                        Layout.fillWidth: true
                        implicitHeight: statusCardLayout.implicitHeight + 20

                        ColumnLayout {
                            id: statusCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Label {
                                text: qsTr("Status")
                                font.bold: true
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            Label {
                                Layout.fillWidth: true
                                text: Models.PlaybackManager.statusText
                                wrapMode: Text.WordWrap
                                color: Models.PlaybackManager.colorTextSecondary
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Network mode") + ": " + Models.PlaybackManager.networkMode
                                wrapMode: Text.WordWrap
                                color: Models.PlaybackManager.colorTextSecondary
                            }
                        }
                    }
                }
            }
        }
    }
}
