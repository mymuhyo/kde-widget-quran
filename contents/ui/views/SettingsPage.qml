import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../models" as Models
import "../components" as Components

ColumnLayout {
    id: root

    property bool narrowLayout: false
    property real scaleFactor: Models.PlaybackManager.uiScale

    spacing: 12
    implicitHeight: comfortCard.implicitHeight
                  + shortcutsCard.implicitHeight
                  + statusCard.implicitHeight
                  + (spacing * 2)

    // Helper component for `<kbd>` keys
    component KbdKey : Rectangle {
        property string keyText: ""
        implicitWidth: kbdLabel.implicitWidth + 12
        implicitHeight: Math.round(20 * root.scaleFactor)
        color: Models.PlaybackManager.colorSurfaceMuted
        border.width: 1
        border.color: Models.PlaybackManager.colorBorder
        radius: 5

        // Key cap shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: parent.height - 2
            radius: 5
            color: Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.15)
            z: -1
        }

        Label {
            id: kbdLabel
            anchors.centerIn: parent
            text: parent.keyText
            color: Models.PlaybackManager.colorTextPrimary
            font.pixelSize: Math.round(10.5 * root.scaleFactor)
            font.family: "monospace"
            font.bold: true
        }
    }

    // Comfort (UI scale settings)
    Components.SurfaceCard {
        id: comfortCard
        Layout.fillWidth: true
        implicitHeight: comfortCardLayout.implicitHeight + 20

        ColumnLayout {
            id: comfortCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Comfort")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: qsTr("UI size")
                    color: Models.PlaybackManager.colorTextPrimary
                    font.pixelSize: Math.round(12 * root.scaleFactor)
                    Layout.preferredWidth: root.narrowLayout ? 56 : 70
                }

                Slider {
                    id: uiScaleSlider
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
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                    font.bold: true
                    Layout.preferredWidth: root.narrowLayout ? 42 : 48
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // Interactive Keyboard Shortcuts Card
    Components.SurfaceCard {
        id: shortcutsCard
        Layout.fillWidth: true
        implicitHeight: shortcutsCardLayout.implicitHeight + 20

        ColumnLayout {
            id: shortcutsCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Shortcuts")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.narrowLayout ? 1 : 2
                columnSpacing: 16
                rowSpacing: 10

                // Shortcut row helper function
                component ShortcutRow : RowLayout {
                    property string desc: ""
                    property var keys: []
                    spacing: 8
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: desc
                        color: Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: Math.round(12 * root.scaleFactor)
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight

                        Repeater {
                            model: keys
                            delegate: Row {
                                spacing: 4
                                KbdKey {
                                    keyText: modelData
                                }
                                Label {
                                    text: "+"
                                    visible: index < keys.length - 1
                                    color: Models.PlaybackManager.colorTextSecondary
                                    font.pixelSize: Math.round(11 * root.scaleFactor)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                ShortcutRow {
                    desc: qsTr("Play / Pause")
                    keys: ["Space"]
                }
                ShortcutRow {
                    desc: qsTr("Save bookmark")
                    keys: ["Ctrl", "B"]
                }
                ShortcutRow {
                    desc: qsTr("Previous Track")
                    keys: ["Ctrl", "←"]
                }
                ShortcutRow {
                    desc: qsTr("Next Track")
                    keys: ["Ctrl", "→"]
                }
                ShortcutRow {
                    desc: qsTr("Speed up")
                    keys: ["Ctrl", "↑"]
                }
                ShortcutRow {
                    desc: qsTr("Speed down")
                    keys: ["Ctrl", "↓"]
                }
            }
        }
    }

    // Diagnostics / System Status Card
    Components.SurfaceCard {
        id: statusCard
        Layout.fillWidth: true
        implicitHeight: statusCardLayout.implicitHeight + 20

        ColumnLayout {
            id: statusCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Label {
                text: qsTr("Status & Diagnostics")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 6

                Label {
                    text: qsTr("Playback State")
                    color: Models.PlaybackManager.colorTextSecondary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                }
                Label {
                    text: Models.PlaybackManager.statusText
                    font.bold: true
                    color: Models.PlaybackManager.colorTextPrimary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("Network Mode")
                    color: Models.PlaybackManager.colorTextSecondary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                }
                Label {
                    text: Models.PlaybackManager.networkMode.toUpperCase()
                    font.bold: true
                    color: Models.PlaybackManager.networkMode === "online" ? Models.PlaybackManager.colorPositive : Models.PlaybackManager.colorNeutral
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                }

                Label {
                    text: qsTr("Reciter Provider")
                    color: Models.PlaybackManager.colorTextSecondary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                }
                Label {
                    text: Models.PlaybackManager.providerStatus
                    font.bold: true
                    color: Models.PlaybackManager.colorTextPrimary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
