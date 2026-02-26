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
        
        delegate: SwipeDelegate {
            id: swipeDelegate
            width: ListView.view.width
            height: 48
            
            background: Rectangle {
                color: swipeDelegate.pressed ? Qt.darker(Models.PlaybackManager.colorCard, 1.05) : "transparent"
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
            }
            
            swipe.right: Rectangle {
                width: parent.width
                height: parent.height
                color: "#E74C3C"
                radius: 6
                
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        text: qsTr("Delete")
                        color: "white"
                        font.pixelSize: 14
                    }
                }
            }
            
            onClicked: {
                if (Models.PlaybackManager.queueModel.currentIndex !== index) {
                    Models.PlaybackManager.queueModel.currentIndex = index
                    Models.PlaybackManager.playCurrent(true)
                }
            }
            
            Component.onCompleted: {
                swipe.positionChanged.connect(function() {
                    if (swipe.position === 1.0) {
                        Models.PlaybackManager.queueModel.removeTrack(index)
                    }
                })
            }
        }
    }
}
