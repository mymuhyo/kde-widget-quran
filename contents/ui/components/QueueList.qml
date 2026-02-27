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
            height: 52
            hoverEnabled: true
            
            background: Rectangle {
                color: queueDelegate.down
                    ? Qt.darker(Models.PlaybackManager.colorCard, 1.05)
                    : (queueDelegate.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.06) : "transparent")
                radius: 6
            }
            
            contentItem: RowLayout {
                spacing: 8
                
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: index === Models.PlaybackManager.queueModel.currentIndex ? Models.PlaybackManager.colorAccent : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: (index + 1).toString()
                        color: index === Models.PlaybackManager.queueModel.currentIndex ? "#FFFFFF" : Models.PlaybackManager.colorTextSecondary
                        font.pixelSize: 12
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: model.isFullSurah ? qsTr("Surah ") + model.surahNumber : qsTr("Surah ") + model.surahNumber + qsTr(", Ayah ") + model.ayahNumber
                        color: index === Models.PlaybackManager.queueModel.currentIndex ? Models.PlaybackManager.colorAccent : Models.PlaybackManager.colorTextPrimary
                        font.bold: index === Models.PlaybackManager.queueModel.currentIndex
                        font.pixelSize: 14
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
