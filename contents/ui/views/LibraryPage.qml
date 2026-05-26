import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../models" as Models
import "../components" as Components

ColumnLayout {
    id: root

    property bool narrowLayout: false
    property real scaleFactor: Models.PlaybackManager.uiScale

    spacing: 12
    implicitHeight: quickStartCard.implicitHeight
                  + presetsCard.implicitHeight
                  + bookmarksCard.implicitHeight
                  + (spacing * 2)

    // Quick Start Card
    Components.SurfaceCard {
        id: quickStartCard
        Layout.fillWidth: true
        implicitHeight: quickStartCardLayout.implicitHeight + 20

        ColumnLayout {
            id: quickStartCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Quick Start")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Start a commonly played surah instantly with your selected reciter.")
                color: Models.PlaybackManager.colorTextSecondary
                wrapMode: Text.WordWrap
                font.pixelSize: Math.round(11 * root.scaleFactor)
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.narrowLayout ? 2 : 3
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        { title: qsTr("Al-Fatihah"), subtitle: qsTr("Opening"), number: 1, accent: "#2ecc71" },
                        { title: qsTr("Al-Kahf"), subtitle: qsTr("Friday"), number: 18, accent: "#3498db" },
                        { title: qsTr("Ya-Sin"), subtitle: qsTr("Heart"), number: 36, accent: "#9b59b6" },
                        { title: qsTr("Al-Mulk"), subtitle: qsTr("Night"), number: 67, accent: "#f39c12" },
                        { title: qsTr("Al-Ikhlas"), subtitle: qsTr("Sincerity"), number: 112, accent: "#1abc9c" },
                        { title: qsTr("An-Nas"), subtitle: qsTr("Protection"), number: 114, accent: "#e67e22" }
                    ]

                    delegate: AbstractButton {
                        id: quickStartButton
                        Layout.fillWidth: true
                        implicitHeight: Math.round(58 * root.scaleFactor)
                        enabled: !Models.PlaybackManager.isQueueLoading
                        onClicked: Models.PlaybackManager.requestQuickSurah(modelData.number, true)
                        Accessible.name: modelData.title + ", " + modelData.subtitle

                        background: Rectangle {
                            radius: 12
                            color: quickStartButton.pressed
                                ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.22)
                                : (quickStartButton.hovered
                                    ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.12)
                                    : Models.PlaybackManager.colorSurfaceMuted)
                            border.width: 1
                            border.color: quickStartButton.activeFocus
                                ? Models.PlaybackManager.focusRingColor
                                : (quickStartButton.hovered 
                                    ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.25)
                                    : Models.PlaybackManager.colorBorder)
                            scale: quickStartButton.pressed ? 0.96 : (quickStartButton.hovered ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }

                        contentItem: RowLayout {
                            spacing: 8
                            anchors.fill: parent
                            anchors.margins: 6

                            // Capsule Badge
                            Rectangle {
                                Layout.preferredWidth: Math.round(30 * root.scaleFactor)
                                Layout.preferredHeight: width
                                radius: width / 2
                                color: quickStartButton.hovered
                                    ? Models.PlaybackManager.colorAccent
                                    : Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.08)
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 180 } }

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.number
                                    color: quickStartButton.hovered ? "#FFFFFF" : Models.PlaybackManager.colorTextPrimary
                                    font.bold: true
                                    font.pixelSize: Math.round(11 * root.scaleFactor)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: Models.PlaybackManager.colorTextPrimary
                                    font.bold: true
                                    font.pixelSize: Math.round(12.5 * root.scaleFactor)
                                    elide: Text.ElideRight
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.subtitle
                                    color: Models.PlaybackManager.colorTextSecondary
                                    font.pixelSize: Math.round(10.5 * root.scaleFactor)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Presets Card
    Components.SurfaceCard {
        id: presetsCard
        Layout.fillWidth: true
        implicitHeight: presetsCardLayout.implicitHeight + 20

        ColumnLayout {
            id: presetsCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Presets")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: presetLabel
                    Layout.fillWidth: true
                    placeholderText: qsTr("Create preset from current range...")
                    font.pixelSize: Math.round(12 * root.scaleFactor)
                    
                    background: Rectangle {
                        implicitHeight: Math.round(32 * root.scaleFactor)
                        radius: 8
                        color: Models.PlaybackManager.colorSurfaceMuted
                        border.width: presetLabel.activeFocus ? 2 : 1
                        border.color: presetLabel.activeFocus ? Models.PlaybackManager.focusRingColor : Models.PlaybackManager.colorBorder
                    }
                }

                Button {
                    text: qsTr("Save")
                    enabled: presetLabel.text.trim().length > 0
                    Layout.preferredHeight: Math.round(32 * root.scaleFactor)
                    onClicked: {
                        Models.PlaybackManager.saveCurrentPreset(presetLabel.text)
                        presetLabel.text = ""
                    }
                }
            }

            ListView {
                id: presetsList
                Layout.fillWidth: true
                Layout.preferredHeight:
                    Models.PlaybackManager.presets
                    && Models.PlaybackManager.presets.length > 0
                    ? Math.min(180, contentHeight) : 0
                clip: true
                spacing: 6
                model: Models.PlaybackManager.presets

                delegate: Rectangle {
                    width: presetsList.width
                    height: Math.round(44 * root.scaleFactor)
                    radius: 8
                    color: Models.PlaybackManager.colorSurfaceMuted
                    border.width: 1
                    border.color: Models.PlaybackManager.colorBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Kirigami.Icon {
                            source: "document-save"
                            Layout.preferredWidth: Math.round(16 * root.scaleFactor)
                            Layout.preferredHeight: width
                            visible: source != ""
                            opacity: 0.7
                            color: Models.PlaybackManager.colorTextPrimary
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.pixelSize: Math.round(12 * root.scaleFactor)
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            color: Models.PlaybackManager.colorTextPrimary
                        }

                        ToolButton {
                            id: applyPresetBtn
                            icon.name: "media-playback-start"
                            display: AbstractButton.IconOnly
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Apply preset")
                            Accessible.name: ToolTip.text
                            onClicked: Models.PlaybackManager.applyPreset(modelData)

                            background: Rectangle {
                                implicitWidth: Math.round(28 * root.scaleFactor)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: applyPresetBtn.pressed ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.15) :
                                       (applyPresetBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.08) : "transparent")
                            }
                        }

                        ToolButton {
                            id: deletePresetBtn
                            icon.name: "edit-delete"
                            display: AbstractButton.IconOnly
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Delete")
                            Accessible.name: ToolTip.text
                            onClicked: Models.PlaybackManager.removePreset(modelData.id)

                            background: Rectangle {
                                implicitWidth: Math.round(28 * root.scaleFactor)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: deletePresetBtn.pressed ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.15) :
                                       (deletePresetBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.08) : "transparent")
                            }
                            contentItem: Kirigami.Icon {
                                source: deletePresetBtn.icon.name || ""
                                width: Math.round(14 * root.scaleFactor)
                                height: width
                                color: deletePresetBtn.hovered ? Models.PlaybackManager.colorNegative : Models.PlaybackManager.colorTextSecondary
                            }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("No presets yet")
                visible: !Models.PlaybackManager.presets
                         || Models.PlaybackManager.presets.length === 0
                font.pixelSize: Math.round(12 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextSecondary
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Bookmarks Card
    Components.SurfaceCard {
        id: bookmarksCard
        Layout.fillWidth: true
        implicitHeight: bookmarksCardLayout.implicitHeight + 20

        ColumnLayout {
            id: bookmarksCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Bookmarks")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            ListView {
                id: bookmarksList
                Layout.fillWidth: true
                Layout.preferredHeight:
                    Models.PlaybackManager.bookmarks
                    && Models.PlaybackManager.bookmarks.length > 0
                    ? Math.min(200, contentHeight) : 0
                clip: true
                spacing: 6
                model: Models.PlaybackManager.bookmarks

                delegate: Rectangle {
                    width: bookmarksList.width
                    height: Math.round(44 * root.scaleFactor)
                    radius: 8
                    color: Models.PlaybackManager.colorSurfaceMuted
                    border.width: 1
                    border.color: Models.PlaybackManager.colorBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Kirigami.Icon {
                            source: "bookmark"
                            Layout.preferredWidth: Math.round(16 * root.scaleFactor)
                            Layout.preferredHeight: width
                            visible: source != ""
                            opacity: 0.7
                            color: Models.PlaybackManager.colorTextPrimary
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.pixelSize: Math.round(12 * root.scaleFactor)
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            color: Models.PlaybackManager.colorTextPrimary
                        }

                        ToolButton {
                            id: jumpBookmarkBtn
                            icon.name: "go-jump"
                            display: AbstractButton.IconOnly
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Jump to bookmark")
                            Accessible.name: ToolTip.text
                            onClicked: Models.PlaybackManager.jumpToBookmark(modelData)

                            background: Rectangle {
                                implicitWidth: Math.round(28 * root.scaleFactor)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: jumpBookmarkBtn.pressed ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.15) :
                                       (jumpBookmarkBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.08) : "transparent")
                            }
                        }

                        ToolButton {
                            id: deleteBookmarkBtn
                            icon.name: "edit-delete"
                            display: AbstractButton.IconOnly
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Delete")
                            Accessible.name: ToolTip.text
                            onClicked: Models.PlaybackManager.removeBookmark(modelData.id)

                            background: Rectangle {
                                implicitWidth: Math.round(28 * root.scaleFactor)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: deleteBookmarkBtn.pressed ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.15) :
                                       (deleteBookmarkBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.08) : "transparent")
                            }
                            contentItem: Kirigami.Icon {
                                source: deleteBookmarkBtn.icon.name || ""
                                width: Math.round(14 * root.scaleFactor)
                                height: width
                                color: deleteBookmarkBtn.hovered ? Models.PlaybackManager.colorNegative : Models.PlaybackManager.colorTextSecondary
                            }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("No bookmarks yet")
                visible: !Models.PlaybackManager.bookmarks
                         || Models.PlaybackManager.bookmarks.length === 0
                font.pixelSize: Math.round(12 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextSecondary
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
