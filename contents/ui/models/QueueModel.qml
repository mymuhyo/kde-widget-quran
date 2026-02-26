pragma Singleton
import QtQuick

ListModel {
    id: queueModel
    
    property int currentIndex: -1
    property var currentTrack: count > 0 && currentIndex >= 0 && currentIndex < count ? get(currentIndex) : null

    function loadQueue(array) {
        clear()
        for (var i = 0; i < array.length; i++) {
            append(array[i])
        }
    }

    function addTrack(track) {
        append(track)
    }

    function removeTrack(index) {
        if (index >= 0 && index < count) {
            remove(index)
            if (currentIndex === index) {
                currentIndex = -1
            } else if (currentIndex > index) {
                currentIndex -= 1
            }
        }
    }
}