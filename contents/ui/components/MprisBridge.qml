import QtQuick
import org.kde.quranplayer

MprisManager {
    id: mprisRoot

    property var manager: null

    onPlayRequested: { if (manager) manager.requestPlay() }
    onPauseRequested: { if (manager) manager.requestPause() }
    onPlayPauseRequested: { if (manager) manager.requestTogglePlayPause() }
    onNextRequested: { if (manager) manager.nextTrack() }
    onPreviousRequested: { if (manager) manager.previousTrack() }
    onStopRequested: { if (manager) manager.requestStop() }
}
