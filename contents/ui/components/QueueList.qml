import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../models" as Models

Item {
    id: root

    ListView {
        id: queueView
        anchors.fill: parent
        model: Models.PlaybackManager.queueModel
        clip: true
        spacing: 4

        delegate: ItemDelegate {
            id: queueDelegate
            width: ListView.view.width
            height: 56
            hoverEnabled: true
            readonly property bool isCurrent: index === Models.PlaybackManager.queueModel.currentIndex

            background: Rectangle {
                color: queueDelegate.down
                    ? Qt.darker(Models.PlaybackManager.colorCard, 1.05)
                    : (queueDelegate.isCurrent
                        ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.10)
                        : (queueDelegate.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.06) : "transparent"))
                radius: 8
                border.width: queueDelegate.isCurrent ? 1 : 0
                border.color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.32)

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }
            }

            contentItem: RowLayout {
                spacing: 8

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: queueDelegate.isCurrent ? Models.PlaybackManager.colorAccent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: (index + 1).toString()
                        color: queueDelegate.isCurrent ? "#FFFFFF" : Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: 12
                    }
                }

                Row {
                    visible: queueDelegate.isCurrent && Models.PlaybackManager.isPlaying
                    spacing: 2
                    Layout.preferredWidth: visible ? 18 : 0
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: 3

                        Rectangle {
                            width: 4
                            height: 10
                            radius: 2
                            color: Models.PlaybackManager.colorAccent
                            opacity: 0.45

                            SequentialAnimation on height {
                                running: queueDelegate.isCurrent && Models.PlaybackManager.isPlaying
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 110 }
                                NumberAnimation { to: 18; duration: 260; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 8; duration: 260; easing.type: Easing.InOutQuad }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: Models.PlaybackManager.trackLabelFromParts(model.surahNumber, model.ayahNumber, model.isFullSurah)
                        color: queueDelegate.isCurrent ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorTextPrimary
                        font.bold: queueDelegate.isCurrent
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Text {
                        text: model.reciterName ? model.reciterName : (model.source ? model.source : "")
                        visible: text.length > 0
                        color: Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                ToolButton {
                    icon.name: "edit-delete"
                    display: AbstractButton.IconOnly
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Delete")
                    Accessible.name: qsTr("Delete")
                    onClicked: Models.PlaybackManager.requestDeleteQueueItem(model.trackId)
                }
            }

            onClicked: {
                if (Models.PlaybackManager.queueModel.currentTrackId !== model.trackId) {
                    Models.PlaybackManager.queueModel.setCurrentByTrackId(model.trackId)
                    Models.PlaybackManager.playCurrent(true)
                }
            }
        }
    }
}
