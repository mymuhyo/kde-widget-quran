.pragma library

.import "../data/CuratedReciters.js" as CuratedReciters
.import "../data/SurahMeta.js" as SurahMeta
.import "PlaybackController.js" as PlaybackController

var API_BASE = "https://api.quran.com/api/v4";
var AUDIO_BASE = "https://verses.quran.com";
var REQUEST_TIMEOUT_MS = 8000;
var RANGE_CONCURRENCY = 4;
var TRACK_CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
var _trackCache = {};

function _buildTrackId(reciterId, surahNumber, ayahNumber, isFullSurah) {
  var mode = isFullSurah ? "full" : "ayah";
  return String(reciterId) + "|" + String(surahNumber) + "|" + String(ayahNumber) + "|" + mode;
}

function _trackCacheKey(reciter, surahNumber, ayahNumber, isFullSurah) {
  var reciterKey = reciter && reciter.id ? reciter.id : "unknown";
  return _buildTrackId(reciterKey, surahNumber, ayahNumber, !!isFullSurah);
}

function _cloneTrack(track) {
  if (!track) {
    return null;
  }

  return {
    trackId: track.trackId || "",
    surahNumber: track.surahNumber,
    ayahNumber: track.ayahNumber,
    reciterId: track.reciterId,
    url: track.url,
    isFullSurah: !!track.isFullSurah,
    source: track.source || ""
  };
}

function _getCachedTrack(cacheKey) {
  return _getCachedTrackWithTtl(cacheKey, TRACK_CACHE_TTL_MS);
}

function _getCachedTrackWithTtl(cacheKey, ttlMs) {
  var cached = _trackCache[cacheKey];
  if (!cached) {
    return null;
  }

  var effectiveTtl = ttlMs > 0 ? ttlMs : TRACK_CACHE_TTL_MS;
  if ((Date.now() - cached.cachedAt) > effectiveTtl) {
    delete _trackCache[cacheKey];
    return null;
  }

  return _cloneTrack(cached.track);
}

function _setCachedTrack(cacheKey, track) {
  _trackCache[cacheKey] = {
    cachedAt: Date.now(),
    track: _cloneTrack(track)
  };
}

function _httpGetJson(url, headers, onSuccess, onError, tr) {
  var xhr = new XMLHttpRequest();
  var done = false;
  xhr.timeout = REQUEST_TIMEOUT_MS;

  xhr.ontimeout = function() {
    if (done) {
      return;
    }
    done = true;
    var msg = tr ? tr("Request timeout for %1", url) : ("Request timeout for " + url);
    onError(msg);
  };

  xhr.onreadystatechange = function() {
    if (xhr.readyState !== XMLHttpRequest.DONE || done) {
      return;
    }

    done = true;

    if (xhr.status >= 200 && xhr.status < 300) {
      try {
        var parsed = JSON.parse(xhr.responseText);
        onSuccess(parsed);
      } catch (error) {
        var msg = tr ? tr("Invalid response from provider.") : "Invalid response from provider.";
        onError(msg);
      }
      return;
    }

    var statusMsg = tr ? tr("Provider returned status %1.", xhr.status) : ("Provider returned status " + xhr.status + ".");
    onError(statusMsg);
  };

  xhr.open("GET", url);
  xhr.setRequestHeader("Accept", "application/json");

  if (headers) {
    var keys = Object.keys(headers);
    for (var i = 0; i < keys.length; i += 1) {
      xhr.setRequestHeader(keys[i], headers[keys[i]]);
    }
  }

  xhr.send();
}

function _normalizeReciters(payload, tr) {
  var list = [];
  var rows = payload && payload.recitations ? payload.recitations : [];

  for (var i = 0; i < rows.length; i += 1) {
    var item = rows[i];
    var translatedName = item.translated_name && item.translated_name.name ? item.translated_name.name : "";
    var defaultName = tr ? tr("Reciter %1", item.id) : ("Reciter " + item.id);
    var reciterName = item.reciter_name || translatedName || defaultName;

    list.push({
      id: "qurancom:" + String(item.id),
      providerId: item.id,
      name: reciterName,
      language: item.language_name || "ar",
      styleTags: ["online"],
      audioTemplate: "",
      source: "qurancom"
    });
  }

  return list;
}

function listReciters(onSuccess, onError, tr) {
  var curated = CuratedReciters.list();

  _httpGetJson(API_BASE + "/resources/recitations?language=en", null, function(payload) {
    var online = _normalizeReciters(payload, tr);
    var merged = curated.slice();

    for (var i = 0; i < online.length; i += 1) {
      var exists = false;
      for (var j = 0; j < merged.length; j += 1) {
        if (merged[j].providerId === online[i].providerId) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        merged.push(online[i]);
      }
    }

    onSuccess(merged);
  }, function(message) {
    if (onError) {
      onError(message);
    }
    onSuccess(curated);
  }, tr);
}

function _templateUrl(reciter, surahNumber, ayahNumber) {
  var ayahKey = PlaybackController.ayahKeyPadded(surahNumber, ayahNumber);
  return reciter.audioTemplate.replace("{ayahKey}", ayahKey);
}

function _normalizeAudioUrl(url) {
  if (!url) {
    return "";
  }

  if (url.indexOf("http://") === 0 || url.indexOf("https://") === 0) {
    return url;
  }

  if (url.indexOf("//") === 0) {
    return "https:" + url;
  }

  if (url.charAt(0) === "/") {
    return AUDIO_BASE + url;
  }

  // Quran.com may return relative paths like "Alafasy/mp3/001001.mp3".
  return AUDIO_BASE + "/" + url;
}

function resolveTrack(reciter, surahNumber, ayahNumber, onSuccess, onError, tr) {
  var cacheKey = _trackCacheKey(reciter, surahNumber, ayahNumber, false);
  var cached = _getCachedTrack(cacheKey);
  if (cached) {
    onSuccess(cached);
    return;
  }

  if (reciter.audioTemplate) {
    var templateTrack = {
      trackId: _buildTrackId(reciter.id, surahNumber, ayahNumber, false),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciterId: reciter.id,
      url: _templateUrl(reciter, surahNumber, ayahNumber),
      isFullSurah: false,
      source: "curated"
    };
    _setCachedTrack(cacheKey, templateTrack);
    onSuccess(templateTrack);
    return;
  }

  if (!reciter.providerId) {
    var noSourceMsg = tr ? tr("Selected reciter has no playable source.") : "Selected reciter has no playable source.";
    onError(noSourceMsg);
    return;
  }

  var endpoint = API_BASE + "/recitations/" + reciter.providerId + "/by_ayah/" + surahNumber + ":" + ayahNumber;

  _httpGetJson(endpoint, null, function(payload) {
    var audioUrl = "";

    if (payload && payload.audio_files && payload.audio_files.length > 0) {
      audioUrl = payload.audio_files[0].url || payload.audio_files[0].audio_url || "";
    } else if (payload && payload.audio_file) {
      audioUrl = payload.audio_file.url || payload.audio_file.audio_url || "";
    }

    audioUrl = _normalizeAudioUrl(audioUrl);
    if (!audioUrl) {
      var noAudioMsg = tr ? tr("No audio URL returned for ayah %1:%2.", surahNumber, ayahNumber) : ("No audio URL returned for ayah " + surahNumber + ":" + ayahNumber + ".");
      onError(noAudioMsg);
      return;
    }

    var resolvedTrack = {
      trackId: _buildTrackId(reciter.id, surahNumber, ayahNumber, false),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciterId: reciter.id,
      url: audioUrl,
      isFullSurah: false,
      source: "qurancom"
    };
    _setCachedTrack(cacheKey, resolvedTrack);
    onSuccess(resolvedTrack);
  }, onError, tr);
}

function getCachedOrFetchTrack(trackKey, fetchFn, onSuccess, onError, ttlMs) {
  var cached = _getCachedTrackWithTtl(trackKey, ttlMs);
  if (cached) {
    onSuccess(cached);
    return;
  }

  if (!fetchFn) {
    if (onError) {
      onError("Track not found in cache.");
    }
    return;
  }

  fetchFn(function(track) {
    if (track) {
      _setCachedTrack(trackKey, track);
    }
    onSuccess(track);
  }, onError);
}

function _emitProgress(onProgress, finished, total) {
  if (!onProgress || total <= 0) {
    return;
  }
  var progress = Math.max(0, Math.min(100, Math.round((finished / total) * 100)));
  onProgress(progress);
}

function _extractAyahNumberFromAudioFile(audioFile, surahNumber) {
  if (!audioFile) {
    return 0;
  }

  var verseKey = audioFile.verse_key || audioFile.ayah_key || audioFile.verseKey || "";
  if (verseKey && verseKey.indexOf(":") > 0) {
    var parts = verseKey.split(":");
    if (parts.length === 2 && Number(parts[0]) === Number(surahNumber)) {
      return Number(parts[1]);
    }
  }

  if (audioFile.verse_number !== undefined) {
    return Number(audioFile.verse_number);
  }

  if (audioFile.ayah_number !== undefined) {
    return Number(audioFile.ayah_number);
  }

  return 0;
}

function _fallbackRangeToCurated(surahNumber, startAyah, endAyah, onSuccess, onError, onProgress, originalError) {
  var fallback = CuratedReciters.byId("curated:alafasy");
  if (!fallback) {
    onError(originalError);
    return;
  }

  var total = endAyah - startAyah + 1;
  var fallbackQueue = [];
  for (var ayah = startAyah; ayah <= endAyah; ayah += 1) {
    fallbackQueue.push({
      trackId: _buildTrackId(fallback.id, surahNumber, ayah, false),
      surahNumber: surahNumber,
      ayahNumber: ayah,
      reciterId: fallback.id,
      url: _templateUrl(fallback, surahNumber, ayah),
      isFullSurah: false,
      source: "fallback"
    });
  }

  _emitProgress(onProgress, total, total);
  onSuccess(fallbackQueue);
}

function _buildRangeQueueViaResolve(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress) {
  var total = endAyah - startAyah + 1;
  var queue = new Array(total);
  var nextAyah = startAyah;
  var finished = 0;
  var failed = false;

  function launchNext() {
    if (failed) {
      return;
    }

    if (nextAyah > endAyah) {
      if (finished >= total) {
        onSuccess(queue);
      }
      return;
    }

    var ayah = nextAyah;
    nextAyah += 1;

    resolveTrack(reciter, surahNumber, ayah, function(track) {
      if (failed) {
        return;
      }
      queue[ayah - startAyah] = track;
      finished += 1;
      _emitProgress(onProgress, finished, total);

      if (finished >= total) {
        onSuccess(queue);
        return;
      }
      launchNext();
    }, function(message) {
      if (failed) {
        return;
      }
      failed = true;
      _fallbackRangeToCurated(surahNumber, startAyah, endAyah, onSuccess, onError, onProgress, message);
    }, tr);
  }

  var workers = Math.min(RANGE_CONCURRENCY, total);
  for (var i = 0; i < workers; i += 1) {
    launchNext();
  }
}

function _buildRangeQueueFromChapter(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress) {
  var endpoint = API_BASE + "/recitations/" + reciter.providerId + "/by_chapter/" + surahNumber + "?per_page=300";
  var total = endAyah - startAyah + 1;

  _httpGetJson(endpoint, null, function(payload) {
    var files = payload && payload.audio_files ? payload.audio_files : [];
    if (!files || files.length === 0) {
      _buildRangeQueueViaResolve(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress);
      return;
    }

    var byAyah = {};
    for (var i = 0; i < files.length; i += 1) {
      var row = files[i];
      var ayahNumber = _extractAyahNumberFromAudioFile(row, surahNumber);
      var audioUrl = _normalizeAudioUrl((row && (row.url || row.audio_url)) || "");
      if (ayahNumber > 0 && audioUrl.length > 0) {
        byAyah[ayahNumber] = audioUrl;
      }
    }

    var queue = [];
    var finished = 0;

    for (var ayah = startAyah; ayah <= endAyah; ayah += 1) {
      var audioUrl = byAyah[ayah];
      if (!audioUrl || audioUrl.length === 0) {
        _buildRangeQueueViaResolve(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress);
        return;
      }

      var track = {
        trackId: _buildTrackId(reciter.id, surahNumber, ayah, false),
        surahNumber: surahNumber,
        ayahNumber: ayah,
        reciterId: reciter.id,
        url: audioUrl,
        isFullSurah: false,
        source: "qurancom"
      };
      _setCachedTrack(_trackCacheKey(reciter, surahNumber, ayah, false), track);
      queue.push(track);
      finished += 1;
      _emitProgress(onProgress, finished, total);
    }

    onSuccess(queue);
  }, function() {
    _buildRangeQueueViaResolve(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress);
  }, tr);
}

function buildRangeQueue(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress) {
  if (endAyah < startAyah) {
    onSuccess([]);
    return;
  }

  var total = endAyah - startAyah + 1;

  if (reciter.audioTemplate) {
    var templateQueue = [];
    for (var ayah = startAyah; ayah <= endAyah; ayah += 1) {
      var templateTrack = {
        trackId: _buildTrackId(reciter.id, surahNumber, ayah, false),
        surahNumber: surahNumber,
        ayahNumber: ayah,
        reciterId: reciter.id,
        url: _templateUrl(reciter, surahNumber, ayah),
        isFullSurah: false,
        source: "curated"
      };
      templateQueue.push(templateTrack);
      _setCachedTrack(_trackCacheKey(reciter, surahNumber, ayah, false), templateTrack);
      _emitProgress(onProgress, ayah - startAyah + 1, total);
    }
    onSuccess(templateQueue);
    return;
  }

  if (reciter.providerId) {
    _buildRangeQueueFromChapter(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress);
    return;
  }

  _buildRangeQueueViaResolve(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, onProgress);
}

function buildQueueRangeOptimized(reciter, surahNumber, startAyah, endAyah, options, onSuccess, onError, tr) {
  var opts = options || {};
  buildRangeQueue(reciter, surahNumber, startAyah, endAyah, onSuccess, onError, tr, opts.onProgress);
}

function prefetchTracks(tracks, concurrency, onDone) {
  var list = tracks || [];
  if (list.length === 0) {
    if (onDone) {
      onDone();
    }
    return;
  }

  var limit = Math.max(1, concurrency || RANGE_CONCURRENCY);
  var cursor = 0;
  var active = 0;
  var completed = false;

  function finishIfDone() {
    if (!completed && cursor >= list.length && active === 0) {
      completed = true;
      if (onDone) {
        onDone();
      }
    }
  }

  function startNext() {
    while (active < limit && cursor < list.length) {
      var item = list[cursor];
      cursor += 1;

      var url = typeof item === "string" ? item : (item && item.url ? item.url : "");
      if (!url) {
        finishIfDone();
        continue;
      }

      active += 1;
      var xhr = new XMLHttpRequest();
      xhr.timeout = REQUEST_TIMEOUT_MS;
      var requestFinished = false;

      var done = function() {
        if (requestFinished) {
          return;
        }
        requestFinished = true;
        active -= 1;
        finishIfDone();
        startNext();
      };

      xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
          done();
        }
      };
      xhr.ontimeout = done;
      xhr.onerror = done;

      try {
        xhr.open("HEAD", url);
        xhr.send();
      } catch (e) {
        done();
      }
    }
    finishIfDone();
  }

  startNext();
}

function resolveFullSurahTrack(reciter, surahNumber, onSuccess, onError, tr) {
  var cacheKey = _trackCacheKey(reciter, surahNumber, 1, true);
  var cached = _getCachedTrack(cacheKey);
  if (cached) {
    onSuccess(cached);
    return;
  }

  if (!reciter || !reciter.providerId) {
    var noFullSurahMsg = tr ? tr("Selected reciter does not support full surah playback.") : "Selected reciter does not support full surah playback.";
    onError(noFullSurahMsg);
    return;
  }

  var endpoint = API_BASE + "/chapter_recitations/" + reciter.providerId + "/" + surahNumber + "?language=en";

  _httpGetJson(endpoint, null, function(payload) {
    var audioUrl = "";

    if (payload && payload.audio_file) {
      audioUrl = payload.audio_file.audio_url || payload.audio_file.url || "";
    } else if (payload && payload.chapter_recitation) {
      audioUrl = payload.chapter_recitation.audio_url || payload.chapter_recitation.url || "";
    }

    audioUrl = _normalizeAudioUrl(audioUrl);
    if (!audioUrl) {
      var noFullUrlMsg = tr ? tr("No full surah audio URL returned for surah %1.", surahNumber) : ("No full surah audio URL returned for surah " + surahNumber + ".");
      onError(noFullUrlMsg);
      return;
    }

    var fullTrack = {
      trackId: _buildTrackId(reciter.id, surahNumber, 1, true),
      surahNumber: surahNumber,
      ayahNumber: 1,
      reciterId: reciter.id,
      url: audioUrl,
      isFullSurah: true,
      source: "qurancom"
    };
    _setCachedTrack(cacheKey, fullTrack);
    onSuccess(fullTrack);
  }, onError, tr);
}

function buildFullSurahQueue(reciter, surahNumber, onSuccess, onError, tr, onProgress) {
  resolveFullSurahTrack(reciter, surahNumber, function(track) {
    if (onProgress) {
      onProgress(100);
    }
    onSuccess([track]);
  }, function(fullSurahError) {
    var maxAyah = SurahMeta.ayahCount(surahNumber);
    if (maxAyah <= 0) {
      onError(fullSurahError);
      return;
    }

    buildRangeQueue(reciter, surahNumber, 1, maxAyah, function(queue) {
      onSuccess(queue);
    }, function(rangeError) {
      onError(fullSurahError + " " + rangeError);
    }, tr, onProgress);
  }, tr);
}
