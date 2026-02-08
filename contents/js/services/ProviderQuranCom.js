.pragma library

.import "../data/CuratedReciters.js" as CuratedReciters
.import "../data/SurahMeta.js" as SurahMeta
.import "PlaybackController.js" as PlaybackController

var API_BASE = "https://api.quran.com/api/v4";
var AUDIO_BASE = "https://verses.quran.com";
var REQUEST_TIMEOUT_MS = 12000;

function _httpGetJson(url, headers, onSuccess, onError) {
  var xhr = new XMLHttpRequest();
  var done = false;
  xhr.timeout = REQUEST_TIMEOUT_MS;

  xhr.ontimeout = function() {
    if (done) {
      return;
    }
    done = true;
    onError("Request timeout for " + url);
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
        onError("Invalid response from provider.");
      }
      return;
    }

    onError("Provider returned status " + xhr.status + ".");
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

function _normalizeReciters(payload) {
  var list = [];
  var rows = payload && payload.recitations ? payload.recitations : [];

  for (var i = 0; i < rows.length; i += 1) {
    var item = rows[i];
    var translatedName = item.translated_name && item.translated_name.name ? item.translated_name.name : "";
    var reciterName = item.reciter_name || translatedName || ("Reciter " + item.id);

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

function listReciters(onSuccess, onError) {
  var curated = CuratedReciters.list();

  _httpGetJson(API_BASE + "/resources/recitations?language=en", null, function(payload) {
    var online = _normalizeReciters(payload);
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
  });
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

function resolveTrack(reciter, surahNumber, ayahNumber, onSuccess, onError) {
  if (reciter.audioTemplate) {
    onSuccess({
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciterId: reciter.id,
      url: _templateUrl(reciter, surahNumber, ayahNumber)
    });
    return;
  }

  if (!reciter.providerId) {
    onError("Selected reciter has no playable source.");
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
      onError("No audio URL returned for ayah " + surahNumber + ":" + ayahNumber + ".");
      return;
    }

    onSuccess({
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      reciterId: reciter.id,
      url: audioUrl
    });
  }, onError);
}

function buildRangeQueue(reciter, surahNumber, startAyah, endAyah, onSuccess, onError) {
  var queue = [];
  var cursor = startAyah;

  function pushNext() {
    if (cursor > endAyah) {
      onSuccess(queue);
      return;
    }

    resolveTrack(reciter, surahNumber, cursor, function(track) {
      queue.push(track);
      cursor += 1;
      pushNext();
    }, function(message) {
      if (reciter.audioTemplate) {
        onError(message);
        return;
      }

      var fallback = CuratedReciters.byId("curated:alafasy");
      if (!fallback) {
        onError(message);
        return;
      }

      queue = [];
      for (var ayah = startAyah; ayah <= endAyah; ayah += 1) {
        queue.push({
          surahNumber: surahNumber,
          ayahNumber: ayah,
          reciterId: fallback.id,
          url: _templateUrl(fallback, surahNumber, ayah)
        });
      }
      onSuccess(queue);
    });
  }

  pushNext();
}

function resolveFullSurahTrack(reciter, surahNumber, onSuccess, onError) {
  if (!reciter || !reciter.providerId) {
    onError("Selected reciter does not support full surah playback.");
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
      onError("No full surah audio URL returned for surah " + surahNumber + ".");
      return;
    }

    onSuccess({
      surahNumber: surahNumber,
      ayahNumber: 1,
      reciterId: reciter.id,
      url: audioUrl,
      isFullSurah: true
    });
  }, onError);
}

function buildFullSurahQueue(reciter, surahNumber, onSuccess, onError) {
  resolveFullSurahTrack(reciter, surahNumber, function(track) {
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
    });
  });
}
