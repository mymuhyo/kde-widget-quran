.pragma library

.import "../data/CuratedReciters.js" as CuratedReciters
.import "../data/SurahMeta.js" as SurahMeta
.import "PlaybackController.js" as PlaybackController

var API_BASE = "https://api.quran.com/api/v4";
var AUDIO_BASE = "https://verses.quran.com";
var REQUEST_TIMEOUT_MS = 12000;
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
  var cached = _trackCache[cacheKey];
  if (!cached) {
    return null;
  }

  if ((Date.now() - cached.cachedAt) > TRACK_CACHE_TTL_MS) {
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
    var msg = tr ? tr("Selected reciter has no playable source.") : "Selected reciter has no playable source.";
    onError(msg);
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
      var msg = tr ? tr("No audio URL returned for ayah %1:%2.", surahNumber, ayahNumber) : ("No audio URL returned for ayah " + surahNumber + ":" + ayahNumber + ".");
      onError(msg);
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

function _emitProgress(onProgress, finished, total) {
  if (!onProgress || total <= 0) {
    return;
  }
  var progress = Math.max(0, Math.min(100, Math.round((finished / total) * 100)));
  onProgress(progress);
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
      templateQueue.push({
        trackId: _buildTrackId(reciter.id, surahNumber, ayah, false),
        surahNumber: surahNumber,
        ayahNumber: ayah,
        reciterId: reciter.id,
        url: _templateUrl(reciter, surahNumber, ayah),
        isFullSurah: false,
        source: "curated"
      });
      _emitProgress(onProgress, ayah - startAyah + 1, total);
    }
    onSuccess(templateQueue);
    return;
  }

  var queue = new Array(total);
  var nextAyah = startAyah;
  var finished = 0;
  var failed = false;

  function fallbackToCurated(originalError) {
    var fallback = CuratedReciters.byId("curated:alafasy");
    if (!fallback) {
      onError(originalError);
      return;
    }

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
      fallbackToCurated(message);
    }, tr);
  }

  var workers = Math.min(RANGE_CONCURRENCY, total);
  for (var i = 0; i < workers; i += 1) {
    launchNext();
  }
}

function resolveFullSurahTrack(reciter, surahNumber, onSuccess, onError, tr) {
  var cacheKey = _trackCacheKey(reciter, surahNumber, 1, true);
  var cached = _getCachedTrack(cacheKey);
  if (cached) {
    onSuccess(cached);
    return;
  }

  if (!reciter || !reciter.providerId) {
    var msg = tr ? tr("Selected reciter does not support full surah playback.") : "Selected reciter does not support full surah playback.";
    onError(msg);
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
      var msg = tr ? tr("No full surah audio URL returned for surah %1.", surahNumber) : ("No full surah audio URL returned for surah " + surahNumber + ".");
      onError(msg);
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
