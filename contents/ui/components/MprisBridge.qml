import QtQuick
import org.kde.quranplayer

MprisManager {
    id: mprisRoot

    property var manager: null

    onPlayRequested: { if (manager) manager.player.play() }
    onPauseRequested: { if (manager) manager.player.pause() }
    onPlayPauseRequested: { if (manager) manager.togglePlayPause() }
    onNextRequested: { if (manager) manager.nextTrack() }
    onPreviousRequested: { if (manager) manager.previousTrack() }
    onStopRequested: { if (manager) manager.player.stop() }
}
