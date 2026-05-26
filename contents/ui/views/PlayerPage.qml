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
    implicitHeight: rangeCard.implicitHeight
                  + proControlsCard.implicitHeight
                  + queueCard.implicitHeight
                  + (spacing * 2)

    // Playback Range Selection Card
    Components.SurfaceCard {
        id: rangeCard
        Layout.fillWidth: true
        implicitHeight: rangeCardLayout.implicitHeight + 20

        ColumnLayout {
            id: rangeCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Playback Range")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            Components.RangePicker {
                Layout.fillWidth: true
            }
        }
    }

    // Playback Tools Card
    Components.SurfaceCard {
        id: proControlsCard
        Layout.fillWidth: true
        implicitHeight: proControlsLayout.implicitHeight + 20

        ColumnLayout {
            id: proControlsLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Playback Tools")
                    font.bold: true
                    font.pixelSize: Math.round(14 * root.scaleFactor)
                    color: Models.PlaybackManager.colorTextPrimary
                }

                Label {
                    text: Models.PlaybackManager.speed.toFixed(2) + "×"
                    color: Models.PlaybackManager.colorTextSecondary
                    font.pixelSize: Math.round(11 * root.scaleFactor)
                }
            }

            Components.ProControls {
                Layout.fillWidth: true
            }
        }
    }

    // Queue Card
    Components.SurfaceCard {
        id: queueCard
        Layout.fillWidth: true
        implicitHeight: queueCardLayout.implicitHeight + 20

        ColumnLayout {
            id: queueCardLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Label {
                text: qsTr("Queue")
                font.bold: true
                font.pixelSize: Math.round(14 * root.scaleFactor)
                color: Models.PlaybackManager.colorTextPrimary
            }

            Components.QueueList {
                id: queueListComp
                Layout.fillWidth: true
                Layout.preferredHeight:
                    Models.PlaybackManager.queueModel
                    && Models.PlaybackManager.queueModel.count > 0
                    ? Math.min(220, Models.PlaybackManager.queueModel.count * Math.round(54 * root.scaleFactor)) : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: !Models.PlaybackManager.queueModel
                         || Models.PlaybackManager.queueModel.count === 0
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Queue is empty")
                    color: Models.PlaybackManager.colorTextSecondary
                    font.pixelSize: Math.round(12 * root.scaleFactor)
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Button {
                        text: qsTr("Build Queue")
                        icon.name: "list-add"
                        enabled: !Models.PlaybackManager.isQueueLoading
                        onClicked: Models.PlaybackManager.requestBuildQueue({ autoPlay: false })
                    }

                    Button {
                        text: qsTr("Play Now")
                        icon.name: "media-playback-start"
                        enabled: !Models.PlaybackManager.isQueueLoading
                        onClicked: Models.PlaybackManager.requestBuildQueue({ autoPlay: true })
                    }
                }
            }
        }
    }
}
