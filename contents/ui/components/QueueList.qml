import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
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
            height: Math.round(54 * (Models.PlaybackManager.uiScale || 1.0))
            hoverEnabled: true
            readonly property bool isCurrent: index === Models.PlaybackManager.queueModel.currentIndex

            background: Rectangle {
                color: queueDelegate.down
                    ? Qt.darker(Models.PlaybackManager.colorCard, 1.05)
                    : (queueDelegate.isCurrent
                        ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.08)
                        : (queueDelegate.hovered 
                            ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.04) 
                            : Qt.rgba(Models.PlaybackManager.colorCard.r, Models.PlaybackManager.colorCard.g, Models.PlaybackManager.colorCard.b, 0.15)))
                radius: 10
                
                border.width: 1
                border.color: queueDelegate.isCurrent 
                    ? Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.25)
                    : (queueDelegate.hovered 
                        ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.1) 
                        : Qt.rgba(Models.PlaybackManager.colorBorder.r, Models.PlaybackManager.colorBorder.g, Models.PlaybackManager.colorBorder.b, 0.3))

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 180 }
                }
            }

            contentItem: RowLayout {
                spacing: 10

                // Badge Container
                Rectangle {
                    width: Math.round(26 * (Models.PlaybackManager.uiScale || 1.0))
                    height: width
                    radius: width / 2
                    color: queueDelegate.isCurrent ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorSurfaceMuted
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6

                    Text {
                        anchors.centerIn: parent
                        text: (index + 1).toString()
                        color: queueDelegate.isCurrent ? "#FFFFFF" : Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: Math.round(11 * (Models.PlaybackManager.uiScale || 1.0))
                        font.weight: Font.DemiBold
                    }
                }

                // Enhanced Equalizer Visualizer (4 bars)
                Row {
                    visible: queueDelegate.isCurrent && Models.PlaybackManager.isPlaying
                    spacing: 2
                    Layout.preferredWidth: visible ? 20 : 0
                    Layout.alignment: Qt.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: 4

                        Rectangle {
                            width: 3
                            height: 6
                            radius: 1.5
                            color: Models.PlaybackManager.colorAccent
                            anchors.bottom: parent.bottom

                            SequentialAnimation on height {
                                running: queueDelegate.isCurrent && Models.PlaybackManager.isPlaying
                                loops: Animation.Infinite
                                PauseAnimation { duration: index * 80 }
                                NumberAnimation { to: index == 0 ? 16 : (index == 1 ? 20 : (index == 2 ? 14 : 18)); duration: index == 0 ? 280 : (index == 1 ? 220 : (index == 2 ? 260 : 300)); easing.type: Easing.InOutSine }
                                NumberAnimation { to: 6; duration: index == 0 ? 280 : (index == 1 ? 220 : (index == 2 ? 260 : 300)); easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        text: Models.PlaybackManager.trackLabelFromParts(model.surahNumber, model.ayahNumber, model.isFullSurah)
                        color: queueDelegate.isCurrent ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorTextPrimary
                        font.bold: queueDelegate.isCurrent
                        font.pixelSize: Math.round(13 * (Models.PlaybackManager.uiScale || 1.0))
                        font.weight: queueDelegate.isCurrent ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    Text {
                        text: model.reciterName ? model.reciterName : (model.source ? model.source : "")
                        visible: text.length > 0
                        color: Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: Math.round(10.5 * (Models.PlaybackManager.uiScale || 1.0))
                        elide: Text.ElideRight
                    }
                }

                // Sleek Custom Delete Button
                ToolButton {
                    id: deleteBtn
                    icon.name: "edit-delete"
                    display: AbstractButton.IconOnly
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Delete")
                    Accessible.name: qsTr("Delete")
                    onClicked: Models.PlaybackManager.requestDeleteQueueItem(model.trackId)
                    Layout.rightMargin: 4
                    Layout.alignment: Qt.AlignVCenter

                    background: Rectangle {
                        implicitWidth: Math.round(28 * (Models.PlaybackManager.uiScale || 1.0))
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: deleteBtn.pressed ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.15) :
                               (deleteBtn.hovered ? Qt.rgba(Models.PlaybackManager.colorNegative.r, Models.PlaybackManager.colorNegative.g, Models.PlaybackManager.colorNegative.b, 0.08) : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    contentItem: Kirigami.Icon {
                        source: deleteBtn.icon.name || ""
                        anchors.centerIn: parent
                        width: Math.round(14 * (Models.PlaybackManager.uiScale || 1.0))
                        height: width
                        color: deleteBtn.hovered ? Models.PlaybackManager.colorNegative : Models.PlaybackManager.colorTextSecondary
                    }
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
