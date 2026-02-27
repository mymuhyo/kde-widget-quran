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
    readonly property bool showStatusBanner:
        Models.PlaybackManager.isQueueLoading
        || (Models.PlaybackManager.statusText
            && Models.PlaybackManager.statusText.length > 0
            && Models.PlaybackManager.statusText !== qsTr("Ready"))

    implicitWidth: 540
    implicitHeight: 760

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

                ColumnLayout {
                    id: nowPlayingLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Title
                    Label {
                        text: qsTr("Quran Player")
                        font.bold: true
                        font.pixelSize: Math.round(22 * root.scaleFactor)
                        color: Models.PlaybackManager.colorTextPrimary
                    }

                    // Current track
                    Label {
                        Layout.fillWidth: true
                        text: Models.PlaybackManager.currentTrackLabel()
                        color: Models.PlaybackManager.colorTextPrimary
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: Math.round(14 * root.scaleFactor)

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
                        font.pixelSize: Math.round(12 * root.scaleFactor)
                    }

                    // ── Seek Slider ─────────────────────────────────
                    Slider {
                        id: seekSlider
                        Layout.fillWidth: true
                        from: 0
                        to: Math.max(1, Models.PlaybackManager.playbackDurationMs)
                        value: Models.PlaybackManager.playbackPositionMs
                        enabled: Models.PlaybackManager.currentTrack
                        onMoved: Models.PlaybackManager.seekTo(value)

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
                            width: seekSlider.pressed ? 16 : 12
                            height: width
                            radius: width / 2
                            color: Models.PlaybackManager.colorAccent
                            border.color: Qt.lighter(Models.PlaybackManager.colorAccent, 1.3)
                            border.width: 1

                            Behavior on width {
                                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Transport controls
                    Components.TransportControls {
                        Layout.fillWidth: true
                        compact: root.narrowLayout
                    }

                    // Status banner
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.showStatusBanner

                        BusyIndicator {
                            running: Models.PlaybackManager.isQueueLoading
                            visible: running
                            implicitWidth: 16
                            implicitHeight: 16
                        }

                        Label {
                            Layout.fillWidth: true
                            text: Models.PlaybackManager.statusText
                            color: Models.PlaybackManager.colorTextSecondary
                            wrapMode: Text.WordWrap
                            font.pixelSize: Math.round(11 * root.scaleFactor)
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
                        narrowLayout: root.narrowLayout
                        scaleFactor: root.scaleFactor
                    }

                    Components.StyledTabButton {
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Library")
                        narrowLayout: root.narrowLayout
                        scaleFactor: root.scaleFactor
                    }

                    Components.StyledTabButton {
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Settings")
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
                    implicitHeight: textCard.implicitHeight
                                  + rangeCard.implicitHeight
                                  + advancedCard.implicitHeight
                                  + queueCard.implicitHeight
                                  + (spacing * 3)

                    // Ayah Text
                    Components.SurfaceCard {
                        id: textCard
                        Layout.fillWidth: true
                        visible: Models.PlaybackManager.currentAyahTextAr !== ""
                        implicitHeight: visible ? (textCardLayout.implicitHeight + 24) : 0
                        Layout.preferredHeight: implicitHeight

                        ColumnLayout {
                            id: textCardLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Label {
                                Layout.fillWidth: true
                                text: Models.PlaybackManager.currentAyahTextAr
                                font.pixelSize: Math.round(24 * root.scaleFactor)
                                font.family: "Amiri, Scheherazade, serif"
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.WordWrap
                                color: Models.PlaybackManager.colorTextPrimary
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Models.PlaybackManager.colorBorder
                                visible: Models.PlaybackManager.currentAyahTextTr !== ""
                            }

                            Label {
                                Layout.fillWidth: true
                                text: Models.PlaybackManager.currentAyahTextTr
                                font.pixelSize: Math.round(15 * root.scaleFactor)
                                wrapMode: Text.WordWrap
                                color: Models.PlaybackManager.colorTextSecondary
                                visible: text !== ""
                            }
                        }
                    }

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
                                        onClicked: Models.PlaybackManager.applyPreset(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
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
                                        onClicked: Models.PlaybackManager.jumpToBookmark(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
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
                                onToggled: Models.PlaybackManager.telemetryEnabled = checked
                                palette.windowText: Models.PlaybackManager.colorTextPrimary
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Opt-in only. No analytics are sent unless you enable this.")
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
                        }
                    }
                }
            }
        }
    }
}
