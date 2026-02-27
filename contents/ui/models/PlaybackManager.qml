pragma Singleton
import QtQuick
import QtMultimedia
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "../../js/services/PlaybackController.js" as PlaybackController
import "../../js/services/ProviderQuranCom.js" as ProviderQuranCom
import "../../js/services/Storage.js" as Storage
import "../../js/data/SurahMeta.js" as SurahMeta

Item {
    id: manager

    // SystemPalette works in any context, including singletons
    SystemPalette { id: activePal; colorGroup: SystemPalette.Active }

    readonly property color colorBgStart: activePal.window
    readonly property color colorBgEnd: Qt.darker(activePal.window, 1.05)
    readonly property color colorCard: Qt.lighter(activePal.window, 1.08)
    readonly property color colorBorder: Qt.rgba(activePal.windowText.r, activePal.windowText.g, activePal.windowText.b, 0.15)
    readonly property color colorTextPrimary: activePal.windowText
    readonly property color colorTextSecondary: Qt.rgba(activePal.windowText.r, activePal.windowText.g, activePal.windowText.b, 0.6)
    readonly property color colorAccent: activePal.highlight
    readonly property color colorPanelStart: activePal.window
    readonly property color colorPanelEnd: Qt.darker(activePal.window, 1.05)
    readonly property color colorPanelText: activePal.windowText
    readonly property color colorPanelSubtext: Qt.rgba(activePal.windowText.r, activePal.windowText.g, activePal.windowText.b, 0.6)
    
    readonly property color colorPositive: Kirigami.Theme.positiveTextColor || "#27ae60"
    readonly property color colorNeutral: Kirigami.Theme.neutralTextColor || "#f39c12"
    readonly property color colorNegative: Kirigami.Theme.negativeTextColor || "#da4453"
    readonly property color colorSurfaceMuted: Qt.rgba(activePal.windowText.r, activePal.windowText.g, activePal.windowText.b, 0.04)
    readonly property color colorWarningBg: Qt.rgba(colorNeutral.r, colorNeutral.g, colorNeutral.b, 0.14)
    readonly property color colorErrorBg: Qt.rgba(colorNegative.r, colorNegative.g, colorNegative.b, 0.14)
    readonly property color colorInfoBg: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.14)
    readonly property color focusRingColor: Qt.lighter(colorAccent, 1.25)

    property bool expanded: false

    property string uiLocale: Qt.locale().name
    property var surahs: SurahMeta.list()
    property var reciters: []
    property var queueModel: null // Set later
    property var bookmarks: []
    property var presets: []

    property int selectedSurah: 1
    property int startAyah: 1
    property int endAyah: 7
    property int selectedReciterIndex: 0
    property int repeatMode: PlaybackController.REPEAT_NONE
    property int playbackMode: PlaybackController.PLAYBACK_RANGE
    property int ayahRepeatTarget: 1
    property int ayahRepeatCounter: 1
    property real speed: 1.0
    property real volume: 0.85
    property real uiScale: 1.0
    property bool telemetryEnabled: false
    property bool telemetryAvailable: false
    property bool middleClickToggleEnabled: false

    property bool isQueueLoading: false
    property string statusText: qsTr("Ready")
    property string statusKind: "idle" // idle | loading | info | error
    property string statusCode: "none"
    property string statusMessage: qsTr("Ready")
    property string providerStatus: qsTr("Using curated reciters")
    property string currentAyahText: "" // To store the fetched ayah text
    property bool hasErrorStatus: false
    property string lastErrorCode: "none"
    property int ayahTextRequestId: 0
    property int queueBuildProgress: 0
    property string networkMode: "online" // online | degraded | offline-cache
    property int providerErrorStreak: 0
    property int playbackRetryCount: 0
    property string playbackRetryTrackId: ""
    property int pendingSeekMs: -1
    property int pendingSeekAttempts: 0

    property bool abLoopEnabled: false
    property int abStartMs: -1
    property int abEndMs: -1

    property int sleepRemainingMinutes: 0

    readonly property var selectedReciter: reciters.length > 0 && selectedReciterIndex >= 0 && selectedReciterIndex < reciters.length ? reciters[selectedReciterIndex] : null
    readonly property var currentTrack: queueModel && queueModel.count > 0 && queueModel.currentIndex >= 0 && queueModel.currentIndex < queueModel.count ? queueModel.get(queueModel.currentIndex) : null
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property bool canGoNext: queueModel && queueModel.count > 0 && (queueModel.currentIndex < queueModel.count - 1 || repeatMode === PlaybackController.REPEAT_QUEUE || repeatMode === PlaybackController.REPEAT_TRACK)
    readonly property bool canGoPrevious: queueModel && queueModel.count > 0 && queueModel.currentIndex > 0
    readonly property int maxAyahForSurah: SurahMeta.ayahCount(selectedSurah)
    readonly property int playbackPositionMs: player.position
    readonly property int playbackDurationMs: Math.max(0, player.duration)
    readonly property bool playerSeekable: player.seekable

    // MPRIS integration — loaded optionally (works without the C++ plugin)
    property var mprisManager: mprisLoader.item

    Loader {
        id: mprisLoader
        source: "../components/MprisBridge.qml"
        active: true
        asynchronous: true
        onLoaded: {
            if (item) item.manager = manager
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.log("QuranPlayer: MPRIS plugin not available, media keys disabled")
            }
        }
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput { volume: manager.volume }
        playbackRate: manager.speed

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) manager.onTrackEnded()
            if (mediaStatus === MediaPlayer.BufferedMedia || mediaStatus === MediaPlayer.LoadedMedia) {
                manager.playbackRetryCount = 0
                manager.playbackRetryTrackId = ""
            }
            manager.updateMprisStatus()
        }

        onErrorOccurred: function(error, errorString) {
            if (!manager.currentTrack) {
                manager.setErrorStatus(qsTr("Playback error: ") + errorString, "playback")
                return
            }

            var failedTrackId = manager.currentTrack.trackId || ""
            if (manager.playbackRetryTrackId === failedTrackId && manager.playbackRetryCount >= 1) {
                manager.playbackRetryCount = 0
                manager.playbackRetryTrackId = ""
                if (manager.canGoNext) {
                    manager.setErrorStatus(qsTr("Track failed twice, skipping to next"), "playback")
                    manager.nextTrack()
                } else {
                    manager.setErrorStatus(qsTr("Playback error: ") + errorString, "playback")
                }
                return
            }

            manager.playbackRetryTrackId = failedTrackId
            manager.playbackRetryCount += 1
            manager.setLoadingStatus(qsTr("Retrying track..."), "playback")
            playbackRetryTimer.restart()
        }

        onPositionChanged: function(position) {
            if (manager.pendingSeekMs >= 0 && Math.abs(position - manager.pendingSeekMs) < 700) {
                manager.pendingSeekMs = -1
                manager.pendingSeekAttempts = 0
                seekRetryTimer.stop()
            }
            if (PlaybackController.shouldJumpToAB(manager.abLoopEnabled, manager.abStartMs, manager.abEndMs, position)) {
                player.position = manager.abStartMs
                player.play()
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: manager.saveSettings()
    }

    Timer {
        id: sleepTimer
        interval: 60000
        repeat: true
        running: manager.sleepRemainingMinutes > 0
        onTriggered: {
            manager.sleepRemainingMinutes -= 1
            if (manager.sleepRemainingMinutes <= 0) {
                stop()
                manager.sleepRemainingMinutes = 0
                if (manager.isPlaying) manager.togglePlayPause()
                manager.setInfoStatus(qsTr("Sleep timer finished"))
            }
        }
    }

    Timer {
        id: playbackRetryTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!manager.currentTrack) {
                return
            }
            if (manager.playbackRetryTrackId !== manager.currentTrack.trackId) {
                return
            }
            manager.playCurrent(true)
        }
    }

    Timer {
        id: seekRetryTimer
        interval: 180
        repeat: true
        onTriggered: {
            if (manager.pendingSeekMs < 0) {
                stop()
                return
            }
            manager.pendingSeekAttempts += 1
            player.position = manager.pendingSeekMs
            if (manager.pendingSeekAttempts >= 3) {
                stop()
                if (Math.abs(player.position - manager.pendingSeekMs) > 1200) {
                    manager.setErrorStatus(qsTr("Could not seek this stream right now"), "playback")
                }
                manager.pendingSeekMs = -1
                manager.pendingSeekAttempts = 0
                return
            }
        }
    }

    onSelectedSurahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.startAyah !== startAyah) startAyah = normalized.startAyah
        if (normalized.endAyah !== endAyah) endAyah = normalized.endAyah
        if (queueModel) queueModel.clear()
        if (queueModel) queueModel.currentIndex = -1
        scheduleSave()
    }

    onStartAyahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.startAyah !== startAyah) { startAyah = normalized.startAyah; return }
        if (normalized.endAyah !== endAyah) endAyah = normalized.endAyah
        if (queueModel) queueModel.clear()
        if (queueModel) queueModel.currentIndex = -1
        scheduleSave()
    }

    onEndAyahChanged: {
        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        if (normalized.endAyah !== endAyah) { endAyah = normalized.endAyah; return }
        if (queueModel) queueModel.clear()
        if (queueModel) queueModel.currentIndex = -1
        scheduleSave()
    }

    onSelectedReciterIndexChanged: {
        if (queueModel) queueModel.clear()
        if (queueModel) queueModel.currentIndex = -1
        scheduleSave()
    }

    onPlaybackModeChanged: {
        if (queueModel) queueModel.clear()
        if (queueModel) queueModel.currentIndex = -1
        scheduleSave()
    }

    onRepeatModeChanged: scheduleSave()
    onAyahRepeatTargetChanged: scheduleSave()
    onSpeedChanged: scheduleSave()
    onVolumeChanged: scheduleSave()
    onUiScaleChanged: scheduleSave()
    onTelemetryEnabledChanged: {
        scheduleSave()
    }
    onMiddleClickToggleEnabledChanged: scheduleSave()
    onCurrentTrackChanged: {
        playbackRetryCount = 0
        playbackRetryTrackId = ""
        pendingSeekMs = -1
        pendingSeekAttempts = 0
        seekRetryTimer.stop()
        prefetchUpcomingTracks()
    }

    function setInfoStatus(message) {
        statusText = message
        statusMessage = message
        statusKind = "info"
        statusCode = "none"
        hasErrorStatus = false
        lastErrorCode = "none"
    }

    function setLoadingStatus(message, code) {
        statusText = message
        statusMessage = message
        statusKind = "loading"
        statusCode = code && code.length > 0 ? code : "none"
        hasErrorStatus = false
        lastErrorCode = "none"
    }

    function setErrorStatus(message, code) {
        statusText = message
        statusMessage = message
        statusKind = "error"
        statusCode = code && code.length > 0 ? code : "unknown"
        hasErrorStatus = true
        lastErrorCode = code && code.length > 0 ? code : "unknown"
    }

    function updateMprisStatus() {
        if (!mprisManager) return;
        var status = "Stopped";
        if (player.playbackState === MediaPlayer.PlayingState) {
            status = "Playing";
        } else if (player.playbackState === MediaPlayer.PausedState) {
            status = "Paused";
        }
        mprisManager.playbackStatus = status;
    }

    function updateMprisMetadata() {
        if (!mprisManager || !currentTrack) return;
        
        var title = currentTrack.isFullSurah ? qsTr("Surah ") + currentTrack.surahNumber + qsTr(" (Full)") : qsTr("Surah ") + currentTrack.surahNumber + qsTr(", Ayah ") + currentTrack.ayahNumber;
        var artist = selectedReciter ? selectedReciter.name : "Quran Player";
        var rawTrackId = currentTrack.trackId && currentTrack.trackId.length > 0 ? currentTrack.trackId : String(queueModel.currentIndex)
        var trackId = rawTrackId.replace(/[^A-Za-z0-9_]/g, "_")
        
        mprisManager.metadata = {
            "mpris:trackid": "/org/kde/quranplayer/track/" + trackId,
            "mpris:length": Math.max(0, player.duration) * 1000,
            "xesam:title": title,
            "xesam:artist": [artist],
            "xesam:album": "Quran"
        };
    }

    function scheduleSave() { saveTimer.restart() }

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
        Storage.setSetting("middleClickToggleEnabled", middleClickToggleEnabled)
        Storage.setSetting("abLoopEnabled", abLoopEnabled)
        Storage.setSetting("abStartMs", abStartMs)
        Storage.setSetting("abEndMs", abEndMs)
        Storage.setSetting("sleepRemainingMinutes", sleepRemainingMinutes)

        if (currentTrack) {
            Storage.setSetting("lastTrack", {
                surahNumber: currentTrack.surahNumber,
                ayahNumber: currentTrack.ayahNumber,
                queueIndex: queueModel ? queueModel.currentIndex : -1
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
        middleClickToggleEnabled = Storage.getSetting("middleClickToggleEnabled", false)
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

    function setSurah(number) { selectedSurah = number }

    function setReciterById(reciterId) {
        for (var i = 0; i < reciters.length; i += 1) {
            if (reciters[i].id === reciterId) {
                selectedReciterIndex = i
                return
            }
        }
    }

    function setReciterToCuratedFallback() {
        setReciterById("curated:alafasy")
        if (!selectedReciter || selectedReciter.id !== "curated:alafasy") {
            for (var i = 0; i < reciters.length; i += 1) {
                if (reciters[i] && reciters[i].audioTemplate) {
                    selectedReciterIndex = i
                    break
                }
            }
        }
    }

    function resetProviderErrorStreak() {
        providerErrorStreak = 0
        if (networkMode !== "offline-cache") {
            networkMode = "online"
        }
    }

    function registerProviderError() {
        providerErrorStreak += 1
        if (providerErrorStreak >= 3) {
            networkMode = "degraded"
        }
    }

    function refreshReciters() {
        ProviderQuranCom.listReciters(function(list) {
            reciters = list
            providerStatus = qsTr("Reciters loaded")
            resetProviderErrorStreak()
            var savedReciterId = Storage.getSetting("selectedReciterId", "curated:alafasy")
            setReciterById(savedReciterId)
            if (selectedReciterIndex < 0 || selectedReciterIndex >= reciters.length) {
                selectedReciterIndex = 0
            }
            setInfoStatus(qsTr("Ready"))
        }, function(message) {
            providerStatus = qsTr("Using curated reciters")
            registerProviderError()
            if (providerErrorStreak >= 3) {
                setReciterToCuratedFallback()
            }
            setErrorStatus(message, "provider")
        })
    }

    function buildQueue(autoPlay) {
        if (!selectedReciter) {
            setErrorStatus(qsTr("No reciter selected"), "provider")
            return
        }

        var normalized = PlaybackController.normalizeRange(startAyah, endAyah, maxAyahForSurah)
        startAyah = normalized.startAyah
        endAyah = normalized.endAyah

        var isFullSurahMode = playbackMode === PlaybackController.PLAYBACK_FULL_SURAH
        isQueueLoading = true
        queueBuildProgress = 0
        setLoadingStatus(isFullSurahMode ? qsTr("Preparing full surah...") : qsTr("Building queue..."), "queue-build")

        var onQueueReady = function(list) {
            isQueueLoading = false
            queueBuildProgress = 100
            if (queueModel) queueModel.loadQueue(list)
            if (queueModel) queueModel.currentIndex = list.length > 0 ? 0 : -1
            ayahRepeatCounter = 1
            resetProviderErrorStreak()

            for (var i = 0; i < list.length; i += 1) {
                if (list[i] && list[i].source === "fallback") {
                    networkMode = "degraded"
                    break
                }
            }

            var usedFullSurahTrack = isFullSurahMode && list.length === 1 && list[0].isFullSurah
            setInfoStatus(usedFullSurahTrack ? qsTr("Full surah ready") : qsTr("Queue ready"))
            if (isFullSurahMode && !usedFullSurahTrack) {
                setInfoStatus(qsTr("Full surah unavailable, ayah queue ready"))
            }


            if (autoPlay && list.length > 0) playCurrent(true)
            else prefetchUpcomingTracks()
        }

        var onQueueError = function(message) {
            isQueueLoading = false
            queueBuildProgress = 0
            registerProviderError()
            if (providerErrorStreak >= 3) {
                networkMode = "degraded"
            }
            setErrorStatus(qsTr("Queue failed: ") + message, "provider")
        }

        var onQueueProgress = function(progressValue) {
            queueBuildProgress = progressValue
            if (isQueueLoading && progressValue > 0 && progressValue < 100) {
                setLoadingStatus(qsTr("Building queue...") + " " + progressValue + "%", "queue-build")
            }
        }

        if (isFullSurahMode) {
            ProviderQuranCom.buildFullSurahQueue(selectedReciter, selectedSurah, onQueueReady, onQueueError, undefined, onQueueProgress)
        } else {
            ProviderQuranCom.buildQueueRangeOptimized(selectedReciter, selectedSurah, startAyah, endAyah, {
                onProgress: onQueueProgress
            }, onQueueReady, onQueueError)
        }
    }

    function requestBuildQueue(params) {
        var config = params || {}
        if (config.reciterId) {
            setReciterById(config.reciterId)
        }
        if (config.surahNumber !== undefined) {
            selectedSurah = config.surahNumber
        }
        if (config.startAyah !== undefined) {
            startAyah = config.startAyah
        }
        if (config.endAyah !== undefined) {
            endAyah = config.endAyah
        }
        if (config.playbackMode !== undefined) {
            playbackMode = config.playbackMode
        }
        buildQueue(!!config.autoPlay)
    }

    function fetchAyahText(surah, ayah) {
        ayahTextRequestId += 1
        var requestId = ayahTextRequestId
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.quran.com/api/v4/quran/verses/uthmani?verse_key=" + surah + ":" + ayah);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.timeout = 8000
        xhr.ontimeout = function() {
            if (requestId !== ayahTextRequestId) return
            currentAyahText = ""
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (requestId !== ayahTextRequestId) return
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        if (response && response.verses && response.verses.length > 0) {
                            currentAyahText = response.verses[0].text_uthmani;
                        } else {
                            currentAyahText = ""
                        }
                    } catch (e) {
                        console.log("Error parsing ayah text", e);
                        currentAyahText = ""
                    }
                } else {
                    currentAyahText = ""
                }
            }
        }
        xhr.send();
    }

    function playCurrent(resetPosition) {
        if (!currentTrack) {
            ayahTextRequestId += 1
            currentAyahText = ""
            setErrorStatus(qsTr("No track selected"), "playback")
            return
        }
        player.source = currentTrack.url
        if (resetPosition) player.position = 0
        player.play()
        manager.updateMprisMetadata()
        manager.updateMprisStatus()
        
        if (currentTrack.isFullSurah) {
            ayahTextRequestId += 1
            setInfoStatus(qsTr("Playing full Surah ") + currentTrack.surahNumber)
            currentAyahText = "" // Clear ayah text for full surah
        } else {
            setInfoStatus(qsTr("Playing ") + currentTrack.surahNumber + ":" + currentTrack.ayahNumber)
            currentAyahText = ""
            fetchAyahText(currentTrack.surahNumber, currentTrack.ayahNumber)
        }
    }

    function requestPlay() {
        if (!currentTrack) {
            buildQueue(true)
            return
        }
        player.play()
        manager.updateMprisStatus()
        setInfoStatus(qsTr("Playing"))
    }

    function requestPause() {
        if (!currentTrack) return
        player.pause()
        manager.updateMprisStatus()
        setInfoStatus(qsTr("Paused"))
    }

    function requestStop() {
        player.stop()
        manager.updateMprisStatus()
        ayahTextRequestId += 1
        currentAyahText = ""
        setInfoStatus(qsTr("Ready"))
    }

    function requestTogglePlayPause() {
        togglePlayPause()
    }

    function requestRetryLastAction() {
        if (lastErrorCode === "provider") {
            buildQueue(false)
            return
        }
        if (lastErrorCode === "playback") {
            requestPlay()
            return
        }
        if (lastErrorCode === "validation") {
            setInfoStatus(qsTr("Ready"))
            return
        }
        refreshReciters()
    }

    function requestFallbackToCurated() {
        setReciterToCuratedFallback()
        requestBuildQueue({ autoPlay: false })
    }

    function requestDeleteQueueItem(trackId) {
        if (!queueModel || !trackId || trackId.length === 0) return
        var removedCurrent = currentTrack && currentTrack.trackId === trackId
        var removed = queueModel.removeTrackById(trackId)
        if (!removed) return

        if (queueModel.count === 0) {
            requestStop()
            setInfoStatus(qsTr("Queue is empty"))
            return
        }

        if (removedCurrent) {
            playCurrent(true)
            return
        }
        setInfoStatus(qsTr("Removed from queue"))
    }

    function togglePlayPause() {
        if (!currentTrack) { buildQueue(true); return }
        if (isPlaying) requestPause()
        else requestPlay()
    }

    function nextTrack() {
        if (!queueModel || queueModel.count === 0) return
        var next = PlaybackController.nextIndex(queueModel.currentIndex, queueModel.count, repeatMode)
        if (next < 0) {
            player.stop()
            ayahTextRequestId += 1
            currentAyahText = ""
            setInfoStatus(qsTr("Queue finished"))
            return
        }
        queueModel.currentIndex = next
        ayahRepeatCounter = 1
        playCurrent(true)
    }

    function previousTrack() {
        if (!queueModel || queueModel.count === 0) return
        if (player.position > 3000) { player.position = 0; return }
        var previous = PlaybackController.previousIndex(queueModel.currentIndex, queueModel.count)
        queueModel.currentIndex = previous
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
        if (!currentTrack) {
            return false
        }
        var targetMs = ms
        if (playbackDurationMs > 0) {
            targetMs = Math.max(0, Math.min(ms, playbackDurationMs))
        } else {
            targetMs = Math.max(0, ms)
        }
        pendingSeekMs = targetMs
        pendingSeekAttempts = 0
        player.position = targetMs
        seekRetryTimer.restart()
        return true
    }
    function requestSeek(ms) { seekTo(ms) }
    function setSpeed(value) { speed = PlaybackController.clampRate(value) }
    function setVolume(value) { volume = PlaybackController.clampVolume(value) }
    function setUiScale(value) { uiScale = Math.max(0.90, Math.min(1.15, value)) }

    function prefetchUpcomingTracks() {
        if (!queueModel || queueModel.count <= 0) {
            return
        }
        var items = []
        var start = Math.max(0, queueModel.currentIndex + 1)
        var end = Math.min(queueModel.count - 1, start + 2)
        for (var i = start; i <= end; i += 1) {
            var track = queueModel.get(i)
            if (track) {
                items.push(track)
            }
        }
        ProviderQuranCom.prefetchTracks(items, 3)
    }

    function setABStart() {
        abStartMs = player.position
        if (abEndMs >= 0 && abEndMs <= abStartMs) abEndMs = -1
        setInfoStatus(qsTr("A point set"))
    }

    function setABEnd() {
        if (abStartMs < 0) { setErrorStatus(qsTr("Set A point first"), "validation"); return }
        abEndMs = player.position
        if (abEndMs <= abStartMs) { setErrorStatus(qsTr("B must be greater than A"), "validation"); abEndMs = -1; return }
        abLoopEnabled = true
        setInfoStatus(qsTr("A-B loop enabled"))
    }

    function clearABLoop() {
        abLoopEnabled = false
        abStartMs = -1
        abEndMs = -1
        setInfoStatus(qsTr("A-B loop cleared"))
    }

    function setSleepTimer(minutes) {
        sleepRemainingMinutes = Math.max(0, minutes)
        if (sleepRemainingMinutes > 0) {
            sleepTimer.restart()
            setInfoStatus(qsTr("Sleep timer set") + ": " + sleepRemainingMinutes + qsTr(" min"))
        } else {
            sleepTimer.stop()
            setInfoStatus(qsTr("Sleep timer off"))
        }
    }

    function addBookmark() {
        if (!currentTrack || !selectedReciter) {
            setErrorStatus(qsTr("Nothing to bookmark"), "validation")
            return
        }
        Storage.saveBookmark({
            label: currentTrack.isFullSurah ? qsTr("Surah ") + currentTrack.surahNumber + qsTr(" (Full)") : qsTr("Surah ") + currentTrack.surahNumber + qsTr(", Ayah ") + currentTrack.ayahNumber,
            surahNumber: currentTrack.surahNumber,
            ayahNumber: currentTrack.isFullSurah ? 1 : currentTrack.ayahNumber,
            reciterId: selectedReciter.id
        })
        reloadCollections()
        setInfoStatus(qsTr("Bookmark saved"))
    }

    function removeBookmark(id) { Storage.removeBookmark(id); reloadCollections() }

    function jumpToBookmark(bookmark) {
        if (!bookmark) return
        setReciterById(bookmark.reciterId)
        selectedSurah = bookmark.surahNumber
        startAyah = bookmark.ayahNumber
        endAyah = bookmark.ayahNumber
        playbackMode = PlaybackController.PLAYBACK_RANGE
        buildQueue(true)
    }

    function saveCurrentPreset(label) {
        if (!selectedReciter) return
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
        setInfoStatus(qsTr("Preset saved"))
    }

    function removePreset(id) { Storage.removePreset(id); reloadCollections() }

    function applyPreset(preset) {
        if (!preset) return
        setReciterById(preset.reciterId)
        selectedSurah = preset.surahNumber || 1
        startAyah = preset.startAyah || 1
        endAyah = preset.endAyah || startAyah
        playbackMode = preset.playbackMode !== undefined ? preset.playbackMode : PlaybackController.PLAYBACK_RANGE
        if (playbackMode !== PlaybackController.PLAYBACK_RANGE && playbackMode !== PlaybackController.PLAYBACK_FULL_SURAH) playbackMode = PlaybackController.PLAYBACK_RANGE
        setSpeed(preset.speed !== undefined ? preset.speed : 1.0)
        repeatMode = preset.repeatMode !== undefined ? preset.repeatMode : PlaybackController.REPEAT_NONE
        ayahRepeatTarget = preset.ayahRepeatTarget !== undefined ? preset.ayahRepeatTarget : 1
        setVolume(preset.volume !== undefined ? preset.volume : 0.85)
        buildQueue(false)
        setInfoStatus(qsTr("Preset applied"))
    }

    function currentTrackLabel() {
        if (!currentTrack) return qsTr("No track")
        if (currentTrack.isFullSurah) return qsTr("Surah ") + currentTrack.surahNumber + qsTr(" (Full)")
        return qsTr("Surah ") + currentTrack.surahNumber + qsTr(", Ayah ") + currentTrack.ayahNumber
    }

    function currentSurahLabel() { return SurahMeta.label(selectedSurah, uiLocale) }
    function timeLabel(ms) { return PlaybackController.formatClock(ms) }

    Component.onCompleted: {
        Storage.initialize()
    }
}
