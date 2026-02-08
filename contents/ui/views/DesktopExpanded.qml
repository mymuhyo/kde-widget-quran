import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components" as Components

Item {
    id: root

    property var controller
    readonly property real scaleFactor: controller ? controller.uiScale : 1.0
    readonly property bool narrowLayout: width < 430
    readonly property bool showStatusBanner: controller
        && (controller.isQueueLoading || (controller.statusText && controller.statusText.length > 0 && controller.statusText !== qsTr("Ready")))
    readonly property color cardToneStart: controller ? Qt.lighter(controller.colorCard, 1.04) : "#FFFFFF"
    readonly property color cardToneEnd: controller ? controller.colorCard : "#FAFCFE"
    readonly property real cardRadius: 12

    implicitWidth: 540
    implicitHeight: 760

    Rectangle {
        anchors.fill: parent
        radius: 16
        gradient: Gradient {
            GradientStop { position: 0.0; color: controller ? controller.colorBgStart : "#F4F6F8" }
            GradientStop { position: 1.0; color: controller ? controller.colorBgEnd : "#EAEEF2" }
        }
        border.width: 1
        border.color: controller ? controller.colorBorder : "#CDD5DE"
    }

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
            implicitHeight: nowPlayingCard.implicitHeight + tabsCard.implicitHeight + sectionStack.implicitHeight + (spacing * 2)

            Rectangle {
                id: nowPlayingCard
                Layout.fillWidth: true
                implicitHeight: nowPlayingLayout.implicitHeight + 24
                radius: 14
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.cardToneStart }
                    GradientStop { position: 1.0; color: root.cardToneEnd }
                }
                border.width: 1
                border.color: controller ? controller.colorBorder : "#CDD5DE"

                ColumnLayout {
                    id: nowPlayingLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: qsTr("Quran Player")
                        font.bold: true
                        font.pixelSize: Math.round(22 * root.scaleFactor)
                        color: controller ? controller.colorTextPrimary : "#1A222C"
                    }

                    Label {
                        Layout.fillWidth: true
                        text: controller ? controller.currentTrackLabel() : qsTr("No track")
                        color: controller ? controller.colorTextPrimary : "#1A222C"
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: Math.round(14 * root.scaleFactor)
                    }

                    Label {
                        Layout.fillWidth: true
                        text: controller && controller.selectedReciter ? controller.selectedReciter.name : qsTr("Select reciter")
                        color: controller ? controller.colorTextSecondary : "#5B6675"
                        elide: Text.ElideRight
                        font.pixelSize: Math.round(12 * root.scaleFactor)
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: controller ? Math.max(1, controller.playbackDurationMs) : 1
                        value: controller ? controller.playbackPositionMs : 0
                        enabled: controller && controller.currentTrack
                        onMoved: {
                            if (controller) {
                                controller.seekTo(value)
                            }
                        }
                    }

                    Components.TransportControls {
                        Layout.fillWidth: true
                        controller: root.controller
                        compact: root.narrowLayout
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.showStatusBanner

                        BusyIndicator {
                            running: controller && controller.isQueueLoading
                            visible: running
                            implicitWidth: 16
                            implicitHeight: 16
                        }

                        Label {
                            Layout.fillWidth: true
                            text: controller ? controller.statusText : ""
                            color: controller ? controller.colorTextSecondary : "#5B6675"
                            wrapMode: Text.WordWrap
                            font.pixelSize: Math.round(11 * root.scaleFactor)
                        }
                    }
                }
            }

            Rectangle {
                id: tabsCard
                Layout.fillWidth: true
                implicitHeight: sectionTabs.implicitHeight + 10
                radius: root.cardRadius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.cardToneStart }
                    GradientStop { position: 1.0; color: root.cardToneEnd }
                }
                border.width: 1
                border.color: controller ? controller.colorBorder : "#CDD5DE"

                TabBar {
                    id: sectionTabs
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: root.narrowLayout ? 6 : 8
                    background: Item {}

                    TabButton {
                        id: tabPlayer
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Player")
                        font.bold: checked
                        contentItem: Text {
                            text: tabPlayer.text
                            color: sectionTabs.currentIndex === 0 ? "#F5F7FA" : (controller ? controller.colorTextPrimary : "#1A222C")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Math.round((root.narrowLayout ? 12 : 13) * root.scaleFactor)
                            font.bold: sectionTabs.currentIndex === 0
                        }
                        background: Rectangle {
                            radius: 10
                            color: sectionTabs.currentIndex === 0 ? (controller ? controller.colorAccent : "#2D5F93") : (controller ? root.cardToneEnd : "#FAFCFE")
                            border.width: 1
                            border.color: controller ? controller.colorBorder : "#CDD5DE"
                        }
                    }

                    TabButton {
                        id: tabLibrary
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Library")
                        font.bold: checked
                        contentItem: Text {
                            text: tabLibrary.text
                            color: sectionTabs.currentIndex === 1 ? "#F5F7FA" : (controller ? controller.colorTextPrimary : "#1A222C")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Math.round((root.narrowLayout ? 12 : 13) * root.scaleFactor)
                            font.bold: sectionTabs.currentIndex === 1
                        }
                        background: Rectangle {
                            radius: 10
                            color: sectionTabs.currentIndex === 1 ? (controller ? controller.colorAccent : "#2D5F93") : (controller ? root.cardToneEnd : "#FAFCFE")
                            border.width: 1
                            border.color: controller ? controller.colorBorder : "#CDD5DE"
                        }
                    }

                    TabButton {
                        id: tabSettings
                        width: Math.max(0, (sectionTabs.width - (sectionTabs.spacing * 2)) / 3)
                        text: qsTr("Settings")
                        font.bold: checked
                        contentItem: Text {
                            text: tabSettings.text
                            color: sectionTabs.currentIndex === 2 ? "#F5F7FA" : (controller ? controller.colorTextPrimary : "#1A222C")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Math.round((root.narrowLayout ? 12 : 13) * root.scaleFactor)
                            font.bold: sectionTabs.currentIndex === 2
                        }
                        background: Rectangle {
                            radius: 10
                            color: sectionTabs.currentIndex === 2 ? (controller ? controller.colorAccent : "#2D5F93") : (controller ? root.cardToneEnd : "#FAFCFE")
                            border.width: 1
                            border.color: controller ? controller.colorBorder : "#CDD5DE"
                        }
                    }
                }
            }

            StackLayout {
                id: sectionStack
                Layout.fillWidth: true
                implicitHeight: sectionStack.currentItem ? sectionStack.currentItem.implicitHeight : 0
                Layout.preferredHeight: implicitHeight
                currentIndex: sectionTabs.currentIndex

                ColumnLayout {
                    id: playerPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: rangeCard.implicitHeight + advancedCard.implicitHeight + spacing

                    Rectangle {
                        id: rangeCard
                        Layout.fillWidth: true
                        implicitHeight: rangeCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: rangeCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Label {
                                text: qsTr("Playback Range")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            Components.RangePicker {
                                Layout.fillWidth: true
                                controller: root.controller
                            }
                        }
                    }

                    Rectangle {
                        id: advancedCard
                        Layout.fillWidth: true
                        implicitHeight: advancedCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: advancedCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Label {
                                text: qsTr("Advanced Controls")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            Components.ProControls {
                                Layout.fillWidth: true
                                controller: root.controller
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: libraryPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: presetsCard.implicitHeight + bookmarksCard.implicitHeight + spacing

                    Rectangle {
                        id: presetsCard
                        Layout.fillWidth: true
                        implicitHeight: presetsCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: presetsCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Presets")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
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
                                        controller.saveCurrentPreset(presetLabel.text)
                                        presetLabel.text = ""
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: controller && controller.presets && controller.presets.length > 0 ? Math.min(170, contentHeight) : 0
                                clip: true
                                model: controller ? controller.presets : []

                                delegate: RowLayout {
                                    width: ListView.view.width
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: controller ? controller.colorTextPrimary : "#1A222C"
                                    }

                                    ToolButton {
                                        icon.name: "media-playback-start"
                                        onClicked: controller.applyPreset(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
                                        onClicked: controller.removePreset(modelData.id)
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("No presets yet")
                                visible: !controller || !controller.presets || controller.presets.length === 0
                                color: controller ? controller.colorTextSecondary : "#5B6675"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        id: bookmarksCard
                        Layout.fillWidth: true
                        implicitHeight: bookmarksCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: bookmarksCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Bookmarks")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: controller && controller.bookmarks && controller.bookmarks.length > 0 ? Math.min(190, contentHeight) : 0
                                clip: true
                                model: controller ? controller.bookmarks : []

                                delegate: RowLayout {
                                    width: ListView.view.width
                                    spacing: 8

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: controller ? controller.colorTextPrimary : "#1A222C"
                                    }

                                    ToolButton {
                                        icon.name: "go-jump"
                                        onClicked: controller.jumpToBookmark(modelData)
                                    }

                                    ToolButton {
                                        icon.name: "edit-delete"
                                        onClicked: controller.removeBookmark(modelData.id)
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("No bookmarks yet")
                                visible: !controller || !controller.bookmarks || controller.bookmarks.length === 0
                                color: controller ? controller.colorTextSecondary : "#5B6675"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: settingsPage
                    Layout.fillWidth: true
                    spacing: 12
                    implicitHeight: comfortCard.implicitHeight + analyticsCard.implicitHeight + statusCard.implicitHeight + (spacing * 2)

                    Rectangle {
                        id: comfortCard
                        Layout.fillWidth: true
                        implicitHeight: comfortCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: comfortCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Comfort")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: qsTr("UI size")
                                    color: controller ? controller.colorTextPrimary : "#1A222C"
                                    Layout.preferredWidth: root.narrowLayout ? 56 : 70
                                }

                                Slider {
                                    Layout.fillWidth: true
                                    from: 0.90
                                    to: 1.15
                                    stepSize: 0.05
                                    value: controller ? controller.uiScale : 1.0
                                    onMoved: {
                                        if (controller) {
                                            controller.setUiScale(value)
                                        }
                                    }
                                }

                                Label {
                                    text: controller ? Math.round(controller.uiScale * 100) + "%" : "100%"
                                    color: controller ? controller.colorTextSecondary : "#5B6675"
                                    Layout.preferredWidth: root.narrowLayout ? 42 : 48
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: analyticsCard
                        Layout.fillWidth: true
                        implicitHeight: analyticsCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: analyticsCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            CheckBox {
                                text: qsTr("Enable anonymous analytics")
                                checked: controller ? controller.telemetryEnabled : false
                                onToggled: controller.telemetryEnabled = checked
                                palette.windowText: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Opt-in only. No analytics are sent unless you enable this.")
                                color: controller ? controller.colorTextSecondary : "#5B6675"
                                wrapMode: Text.WordWrap
                                font.pixelSize: 11
                            }
                        }
                    }

                    Rectangle {
                        id: statusCard
                        Layout.fillWidth: true
                        implicitHeight: statusCardLayout.implicitHeight + 20
                        radius: root.cardRadius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.cardToneStart }
                            GradientStop { position: 1.0; color: root.cardToneEnd }
                        }
                        border.width: 1
                        border.color: controller ? controller.colorBorder : "#CDD5DE"

                        ColumnLayout {
                            id: statusCardLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Label {
                                text: qsTr("Status")
                                font.bold: true
                                color: controller ? controller.colorTextPrimary : "#1A222C"
                            }

                            Label {
                                Layout.fillWidth: true
                                text: controller ? controller.statusText : ""
                                wrapMode: Text.WordWrap
                                color: controller ? controller.colorTextSecondary : "#5B6675"
                            }
                        }
                    }
                }
            }
        }
    }
}
