pragma Singleton
import QtQuick

ListModel {
    id: queueModel
    
    property int currentIndex: -1
    property var currentTrack: count > 0 && currentIndex >= 0 && currentIndex < count ? get(currentIndex) : null
    property string currentTrackId: currentTrack && currentTrack.trackId ? currentTrack.trackId : ""

    function _generatedTrackId(index, track) {
        var reciterId = track && track.reciterId ? track.reciterId : "unknown"
        var surahNumber = track && track.surahNumber !== undefined ? track.surahNumber : 0
        var ayahNumber = track && track.ayahNumber !== undefined ? track.ayahNumber : 0
        var mode = track && track.isFullSurah ? "full" : "ayah"
        return reciterId + "|" + surahNumber + "|" + ayahNumber + "|" + mode + "|" + index
    }

    function loadQueue(array) {
        clear()
        for (var i = 0; i < array.length; i += 1) {
            var track = array[i] || {}
            if (!track.trackId) {
                track.trackId = _generatedTrackId(i, track)
            }
            append(track)
        }
    }

    function addTrack(track) {
        var nextTrack = track || {}
        if (!nextTrack.trackId) {
            nextTrack.trackId = _generatedTrackId(count, nextTrack)
        }
        append(nextTrack)
    }

    function findIndexByTrackId(trackId) {
        if (!trackId || trackId.length === 0) {
            return -1
        }
        for (var i = 0; i < count; i += 1) {
            var item = get(i)
            if (item && item.trackId === trackId) {
                return i
            }
        }
        return -1
    }

    function setCurrentByTrackId(trackId) {
        var index = findIndexByTrackId(trackId)
        if (index >= 0) {
            currentIndex = index
            return true
        }
        return false
    }

    function removeTrack(index) {
        if (index >= 0 && index < count) {
            remove(index)
            if (currentIndex === index) {
                currentIndex = count > 0 ? Math.min(index, count - 1) : -1
            } else if (currentIndex > index) {
                currentIndex -= 1
            }
            return true
        }
        return false
    }

    function removeTrackById(trackId) {
        var index = findIndexByTrackId(trackId)
        return removeTrack(index)
    }
}
