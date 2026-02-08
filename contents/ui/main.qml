import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "views" as Views
import "../js/data/SurahMeta.js" as SurahMeta
import "../js/services/PlaybackController.js" as PlaybackController
import "../js/services/ProviderQuranCom.js" as ProviderQuranCom
import "../js/services/Storage.js" as Storage
import "../js/services/Telemetry.js" as Telemetry

PlasmoidItem {
    id: root

    readonly property bool panelLike: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var selectedReciter: reciters.length > 0 && selectedReciterIndex >= 0 && selectedReciterIndex < reciters.length ? reciters[selectedReciterIndex] : null
    readonly property var currentTrack: queue.length > 0 && queueIndex >= 0 && queueIndex < queue.length ? queue[queueIndex] : null
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property bool canGoNext: queue.length > 0 && (queueIndex < queue.length - 1 || repeatMode === PlaybackController.REPEAT_QUEUE || repeatMode === PlaybackController.REPEAT_TRACK)
    readonly property bool canGoPrevious: queue.length > 0 && queueIndex > 0
    readonly property int maxAyahForSurah: SurahMeta.ayahCount(selectedSurah)
    readonly property int playbackPositionMs: player.position
    readonly property int playbackDurationMs: Math.max(0, player.duration)

    property string uiLocale: Qt.locale().name
    property var surahs: SurahMeta.list()
    property var reciters: []
    property var queue: []
    property var bookmarks: []
    property var presets: []

    property int selectedSurah: 1
    property int startAyah: 1
    property int endAyah: 7
    property int selectedReciterIndex: 0
    property int queueIndex: -1
    property int repeatMode: PlaybackController.REPEAT_NONE
    property int playbackMode: PlaybackController.PLAYBACK_RANGE
    property int ayahRepeatTarget: 1
    property int ayahRepeatCounter: 1
    property real speed: 1.0
    property real volume: 0.85
    property real uiScale: 1.0
    property bool telemetryEnabled: false

    property bool isQueueLoading: false
    property string statusText: qsTr("Ready")
    property string providerStatus: qsTr("Using curated reciters")

    // Unified color tokens so the widget stays readable regardless of global Plasma theme.
    property color colorBgStart: "#F4F6F8"
    property color colorBgEnd: "#EAEEF2"
    property color colorCard: "#FAFCFE"
    property color colorBorder: "#CDD5DE"
    property color colorTextPrimary: "#1A222C"
    property color colorTextSecondary: "#5B6675"
    property color colorAccent: "#2D5F93"
    property color colorPanelStart: "#1F2833"
    property color colorPanelEnd: "#2A3542"
    property color colorPanelText: "#F5F7FA"
    property color colorPanelSubtext: "#CDD4DE"

    property bool abLoopEnabled: false
    property int abStartMs: -1
    property int abEndMs: -1

    property int sleepRemainingMinutes: 0

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    Layout.minimumWidth: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 180 : 44)
        : 540
    Layout.preferredWidth: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 300 : 44)
        : 540
    Layout.minimumHeight: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 180 : 44)
        : 760
    Layout.preferredHeight: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 300 : 44)
        : 760

    compactRepresentation: Views.PanelCompact {
        controller: root
    }

    fullRepresentation: Views.DesktopExpanded {
        controller: root
    }

    preferredRepresentation: panelLike ? compactRepresentation : fullRepresentation

    AudioOutput {
        id: audioOutput
        volume: root.volume
    }

    MediaPlayer {
        id: player
        audioOutput: audioOutput
        playbackRate: root.speed

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                root.onTrackEnded()
            }
        }

        onErrorOccurred: function(error, errorString) {
            root.statusText = qsTr("Playback error: ") + errorString
            Telemetry.track("playback_error", { code: error, message: errorString })
        }

        onPositionChanged: function(position) {
            if (PlaybackController.shouldJumpToAB(root.abLoopEnabled, root.abStartMs, root.abEndMs, position)) {
                position = root.abStartMs
                play()
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: root.saveSettings()
    }

    Timer {
        id: sleepTimer
        interval: 60000
        repeat: true
        running: root.sleepRemainingMinutes > 0
        onTriggered: {
            root.sleepRemainingMinutes -= 1
            if (root.sleepRemainingMinutes <= 0) {
                stop()
                root.sleepRemainingMinutes = 0
                if (root.isPlaying) {
                    root.togglePlayPause()
                }
                root.statusText = qsTr("Sleep timer finished")
                Telemetry.track("sleep_timer_finished")
            }
        }
    }

    Shortcut {
        sequence: "Space"
        context: Qt.ApplicationShortcut
        onActivated: root.togglePlayPause()
    }

    Shortcut {
        sequence: "Ctrl+Right"
        context: Qt.ApplicationShortcut
        onActivated: root.nextTrack()
    }

    Shortcut {
        sequence: "Ctrl+Left"
        context: Qt.ApplicationShortcut
        onActivated: root.previousTrack()
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        onActivated: root.setSpeed(root.speed + 0.05)
    }

    Shortcut {
        sequence: "Ctrl+Down"
        context: Qt.ApplicationShortcut
        onActivated: root.setSpeed(root.speed - 0.05)
    }

    Shortcut {
        sequence: "Ctrl+B"
        context: Qt.ApplicationShortcut
        onActivated: root.addBookmark()
    }

    Component.onCompleted: {
        Storage.initialize()
        loadSettings()
        reloadCollections()
        Telemetry.setEnabled(telemetryEnabled)
        refreshReciters()
    }

    onSelectedSurahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.startAyah !== startAyah) {
            startAyah = normalized.startAyah
        }
        if (normalized.endAyah !== endAyah) {
            endAyah = normalized.endAyah
        }
        queue = []
        queueIndex = -1
        scheduleSave()
    }

    onStartAyahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.startAyah !== startAyah) {
            startAyah = normalized.startAyah
            return
        }
        if (normalized.endAyah !== endAyah) {
            endAyah = normalized.endAyah
        }
        queue = []
        queueIndex = -1
        scheduleSave()
    }

    onEndAyahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.endAyah !== endAyah) {
            endAyah = normalized.endAyah
            return
        }
        queue = []
        queueIndex = -1
        scheduleSave()
    }

    onSelectedReciterIndexChanged: {
        queue = []
        queueIndex = -1
        scheduleSave()
    }

    onPlaybackModeChanged: {
        queue = []
        queueIndex = -1
        scheduleSave()
    }

    onRepeatModeChanged: scheduleSave()
    onAyahRepeatTargetChanged: scheduleSave()
    onSpeedChanged: scheduleSave()
    onVolumeChanged: scheduleSave()
    onUiScaleChanged: scheduleSave()
    onTelemetryEnabledChanged: {
        Telemetry.setEnabled(telemetryEnabled)
        scheduleSave()
    }

    function scheduleSave() {
        saveTimer.restart()
    }

    function saveSettings() {
        Storage.setSetting("selectedSurah", selectedSurah)
        Storage.setSetting("startAyah", startAyah)
        Storage.setSetting("endAyah", endAyah)
        Storage.setSetting("selectedReciterId", selectedReciter ? selectedReciter.id : "")
        Storage.setSetting("playbackMode", playbackMode)
        Storage.setSetting("repeatMode", repeatMode)
        Storage.setSetting("ayahRepeatTarget", ayahRepeatTarget)
        Storage.setSetting("speed", speed)
        Storage.setSetting("volume", volume)
        Storage.setSetting("uiScale", uiScale)
        Storage.setSetting("telemetryEnabled", telemetryEnabled)
        Storage.setSetting("abLoopEnabled", abLoopEnabled)
        Storage.setSetting("abStartMs", abStartMs)
        Storage.setSetting("abEndMs", abEndMs)
        Storage.setSetting("sleepRemainingMinutes", sleepRemainingMinutes)

        if (currentTrack) {
            Storage.setSetting("lastTrack", {
                surahNumber: currentTrack.surahNumber,
                ayahNumber: currentTrack.ayahNumber,
                queueIndex: queueIndex
            })
        }
    }

    function loadSettings() {
        selectedSurah = Storage.getSetting("selectedSurah", 1)
        var savedStart = Storage.getSetting("startAyah", 1)
        var savedEnd = Storage.getSetting("endAyah", 7)
        playbackMode = Storage.getSetting("playbackMode", PlaybackController.PLAYBACK_RANGE)
        if (playbackMode !== PlaybackController.PLAYBACK_RANGE && playbackMode !== PlaybackController.PLAYBACK_FULL_SURAH) {
            playbackMode = PlaybackController.PLAYBACK_RANGE
        }
        repeatMode = Storage.getSetting("repeatMode", PlaybackController.REPEAT_NONE)
        ayahRepeatTarget = Storage.getSetting("ayahRepeatTarget", 1)
        speed = PlaybackController.clampRate(Storage.getSetting("speed", 1.0))
        volume = PlaybackController.clampVolume(Storage.getSetting("volume", 0.85))
        uiScale = Math.max(0.90, Math.min(1.15, Storage.getSetting("uiScale", 1.0)))
        telemetryEnabled = Storage.getSetting("telemetryEnabled", false)
        abLoopEnabled = Storage.getSetting("abLoopEnabled", false)
        abStartMs = Storage.getSetting("abStartMs", -1)
        abEndMs = Storage.getSetting("abEndMs", -1)
        sleepRemainingMinutes = Storage.getSetting("sleepRemainingMinutes", 0)

        var normalized = PlaybackController.normalizeRange(savedStart, savedEnd, maxAyahForSurah)
        startAyah = normalized.startAyah
        endAyah = normalized.endAyah
    }

    function reloadCollections() {
        bookmarks = Storage.listBookmarks()
        presets = Storage.listPresets()
    }

    function setSurah(number) {
        selectedSurah = number
    }

    function setReciterById(reciterId) {
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i].id === reciterId) {
                selectedReciterIndex = i
                return
            }
        }
    }

    function refreshReciters() {
        ProviderQuranCom.listReciters(function(list) {
            reciters = list
            providerStatus = qsTr("Reciters loaded")

            var savedReciterId = Storage.getSetting("selectedReciterId", "curated:alafasy")
            setReciterById(savedReciterId)

            if (selectedReciterIndex < 0 || selectedReciterIndex >= reciters.length) {
                selectedReciterIndex = 0
            }

            statusText = qsTr("Ready")
            Telemetry.track("reciters_loaded", { count: reciters.length })
        }, function(message) {
            providerStatus = qsTr("Using curated reciters")
            statusText = message
            Telemetry.track("provider_error", { message: message })
        })
    }

    function buildQueue(autoPlay) {
        if (!selectedReciter) {
            statusText = qsTr("No reciter selected")
            return
        }

        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        startAyah = normalized.startAyah
        endAyah = normalized.endAyah

        var isFullSurahMode = playbackMode === PlaybackController.PLAYBACK_FULL_SURAH
        isQueueLoading = true
        statusText = isFullSurahMode ? qsTr("Preparing full surah...") : qsTr("Building queue...")

        var onQueueReady = function(list) {
            isQueueLoading = false
            queue = list
            queueIndex = queue.length > 0 ? 0 : -1
            ayahRepeatCounter = 1

            var usedFullSurahTrack = isFullSurahMode && queue.length === 1 && queue[0].isFullSurah
            statusText = usedFullSurahTrack ? qsTr("Full surah ready") : qsTr("Queue ready")
            if (isFullSurahMode && !usedFullSurahTrack) {
                statusText = qsTr("Full surah unavailable, ayah queue ready")
            }

            Telemetry.track("queue_built", {
                surah: selectedSurah,
                fromAyah: startAyah,
                toAyah: endAyah,
                tracks: queue.length,
                reciter: selectedReciter.id,
                mode: isFullSurahMode ? "full_surah" : "ayah_range",
                fullSurahTrack: usedFullSurahTrack
            })

            if (autoPlay && queue.length > 0) {
                playCurrent(true)
            }
        }

        var onQueueError = function(message) {
            isQueueLoading = false
            statusText = qsTr("Queue failed: ") + message
            Telemetry.track("queue_build_error", {
                message: message,
                mode: isFullSurahMode ? "full_surah" : "ayah_range"
            })
        }

        if (isFullSurahMode) {
            ProviderQuranCom.buildFullSurahQueue(selectedReciter, selectedSurah, onQueueReady, onQueueError)
        } else {
            ProviderQuranCom.buildRangeQueue(selectedReciter, selectedSurah, startAyah, endAyah, onQueueReady, onQueueError)
        }
    }

    function playCurrent(resetPosition) {
        if (!currentTrack) {
            statusText = qsTr("No track selected")
            return
        }

        player.source = currentTrack.url

        if (resetPosition) {
            player.position = 0
        }

        player.play()
        if (currentTrack.isFullSurah) {
            statusText = qsTr("Playing full Surah ") + currentTrack.surahNumber
        } else {
            statusText = qsTr("Playing ") + currentTrack.surahNumber + ":" + currentTrack.ayahNumber
        }
        Telemetry.track("track_play", {
            surah: currentTrack.surahNumber,
            ayah: currentTrack.ayahNumber,
            reciter: currentTrack.reciterId,
            mode: currentTrack.isFullSurah ? "full_surah" : "ayah_range"
        })
    }

    function togglePlayPause() {
        if (!currentTrack) {
            buildQueue(true)
            return
        }

        if (isPlaying) {
            player.pause()
            statusText = qsTr("Paused")
        } else {
            player.play()
            statusText = qsTr("Playing")
        }
    }

    function nextTrack() {
        if (queue.length === 0) {
            return
        }

        var next = PlaybackController.nextIndex(queueIndex, queue.length, repeatMode)
        if (next < 0) {
            player.stop()
            statusText = qsTr("Queue finished")
            return
        }

        queueIndex = next
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function previousTrack() {
        if (queue.length === 0) {
            return
        }

        if (player.position > 3000) {
            player.position = 0
            return
        }

        var previous = PlaybackController.previousIndex(queueIndex, queue.length)
        queueIndex = previous
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function onTrackEnded() {
        if (ayahRepeatCounter < ayahRepeatTarget) {
            ayahRepeatCounter += 1
            playCurrent(true)
            return
        }

        ayahRepeatCounter = 1
        nextTrack()
    }

    function seekTo(ms) {
        player.position = Math.max(0, ms)
    }

    function setSpeed(value) {
        speed = PlaybackController.clampRate(value)
    }

    function setVolume(value) {
        volume = PlaybackController.clampVolume(value)
    }

    function setUiScale(value) {
        uiScale = Math.max(0.90, Math.min(1.15, value))
    }

    function setABStart() {
        abStartMs = player.position
        if (abEndMs >= 0 && abEndMs <= abStartMs) {
            abEndMs = -1
        }
        statusText = qsTr("A point set")
    }

    function setABEnd() {
        if (abStartMs < 0) {
            statusText = qsTr("Set A point first")
            return
        }
        abEndMs = player.position
        if (abEndMs <= abStartMs) {
            statusText = qsTr("B must be greater than A")
            abEndMs = -1
            return
        }
        abLoopEnabled = true
        statusText = qsTr("A-B loop enabled")
    }

    function clearABLoop() {
        abLoopEnabled = false
        abStartMs = -1
        abEndMs = -1
        statusText = qsTr("A-B loop cleared")
    }

    function setSleepTimer(minutes) {
        sleepRemainingMinutes = Math.max(0, minutes)
        if (sleepRemainingMinutes > 0) {
            sleepTimer.restart()
            statusText = qsTr("Sleep timer set") + ": " + sleepRemainingMinutes + qsTr(" min")
            Telemetry.track("sleep_timer_set", { minutes: sleepRemainingMinutes })
        } else {
            sleepTimer.stop()
            statusText = qsTr("Sleep timer off")
        }
    }

    function addBookmark() {
        if (!currentTrack || !selectedReciter) {
            statusText = qsTr("Nothing to bookmark")
            return
        }

        Storage.saveBookmark({
            label: currentTrack.isFullSurah
                ? qsTr("Surah ") + currentTrack.surahNumber + qsTr(" (Full)")
                : qsTr("Surah ") + currentTrack.surahNumber + qsTr(", Ayah ") + currentTrack.ayahNumber,
            surahNumber: currentTrack.surahNumber,
            ayahNumber: currentTrack.isFullSurah ? 1 : currentTrack.ayahNumber,
            reciterId: selectedReciter.id
        })
        reloadCollections()
        statusText = qsTr("Bookmark saved")
        Telemetry.track("bookmark_saved")
    }

    function removeBookmark(id) {
        Storage.removeBookmark(id)
        reloadCollections()
    }

    function jumpToBookmark(bookmark) {
        if (!bookmark) {
            return
        }

        setReciterById(bookmark.reciterId)
        selectedSurah = bookmark.surahNumber
        startAyah = bookmark.ayahNumber
        endAyah = bookmark.ayahNumber
        playbackMode = PlaybackController.PLAYBACK_RANGE

        buildQueue(true)
        Telemetry.track("bookmark_loaded")
    }

    function saveCurrentPreset(label) {
        if (!selectedReciter) {
            return
        }

        Storage.savePreset({
            label: label && label.length > 0 ? label : qsTr("Custom preset"),
            reciterId: selectedReciter.id,
            surahNumber: selectedSurah,
            startAyah: startAyah,
            endAyah: endAyah,
            playbackMode: playbackMode,
            speed: speed,
            repeatMode: repeatMode,
            ayahRepeatTarget: ayahRepeatTarget,
            volume: volume
        })

        reloadCollections()
        statusText = qsTr("Preset saved")
        Telemetry.track("preset_saved")
    }

    function removePreset(id) {
        Storage.removePreset(id)
        reloadCollections()
    }

    function applyPreset(preset) {
        if (!preset) {
            return
        }

        setReciterById(preset.reciterId)
        selectedSurah = preset.surahNumber || 1
        startAyah = preset.startAyah || 1
        endAyah = preset.endAyah || startAyah
        playbackMode = preset.playbackMode !== undefined ? preset.playbackMode : PlaybackController.PLAYBACK_RANGE
        if (playbackMode !== PlaybackController.PLAYBACK_RANGE && playbackMode !== PlaybackController.PLAYBACK_FULL_SURAH) {
            playbackMode = PlaybackController.PLAYBACK_RANGE
        }
        setSpeed(preset.speed !== undefined ? preset.speed : 1.0)
        repeatMode = preset.repeatMode !== undefined ? preset.repeatMode : PlaybackController.REPEAT_NONE
        ayahRepeatTarget = preset.ayahRepeatTarget !== undefined ? preset.ayahRepeatTarget : 1
        setVolume(preset.volume !== undefined ? preset.volume : 0.85)

        buildQueue(false)
        statusText = qsTr("Preset applied")
        Telemetry.track("preset_applied")
    }

    function currentTrackLabel() {
        if (!currentTrack) {
            return qsTr("No track")
        }
        if (currentTrack.isFullSurah) {
            return qsTr("Surah ") + currentTrack.surahNumber + qsTr(" (Full)")
        }
        return qsTr("Surah ") + currentTrack.surahNumber + qsTr(", Ayah ") + currentTrack.ayahNumber
    }

    function currentSurahLabel() {
        return SurahMeta.label(selectedSurah, uiLocale)
    }

    function timeLabel(ms) {
        return PlaybackController.formatClock(ms)
    }
}
