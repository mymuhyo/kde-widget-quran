.pragma library

var REPEAT_NONE = 0;
var REPEAT_TRACK = 1;
var REPEAT_QUEUE = 2;
var PLAYBACK_RANGE = 0;
var PLAYBACK_FULL_SURAH = 1;

function normalizeRange(startAyah, endAyah, maxAyah) {
  var start = Math.max(1, startAyah || 1);
  var end = Math.max(1, endAyah || 1);
  var clamp = Math.max(1, maxAyah || 1);

  if (start > clamp) {
    start = clamp;
  }
  if (end > clamp) {
    end = clamp;
  }
  if (end < start) {
    end = start;
  }

  return {
    startAyah: start,
    endAyah: end
  };
}

function pad3(value) {
  var text = String(value);
  while (text.length < 3) {
    text = "0" + text;
  }
  return text;
}

function ayahKeyPadded(surahNumber, ayahNumber) {
  return pad3(surahNumber) + pad3(ayahNumber);
}

function ayahKey(surahNumber, ayahNumber) {
  return String(surahNumber) + ":" + String(ayahNumber);
}

function nextIndex(currentIndex, queueLength, repeatMode) {
  if (queueLength <= 0) {
    return -1;
  }
  if (repeatMode === REPEAT_TRACK) {
    return currentIndex;
  }

  var next = currentIndex + 1;
  if (next < queueLength) {
    return next;
  }

  if (repeatMode === REPEAT_QUEUE) {
    return 0;
  }

  return -1;
}

function previousIndex(currentIndex, queueLength) {
  if (queueLength <= 0) {
    return -1;
  }

  var previous = currentIndex - 1;
  if (previous < 0) {
    return 0;
  }
  return previous;
}

function shouldJumpToAB(isEnabled, startMs, endMs, currentMs) {
  return isEnabled && startMs >= 0 && endMs > startMs && currentMs >= endMs;
}

function clampRate(rate) {
  var value = rate;
  if (value < 0.5) {
    value = 0.5;
  }
  if (value > 2.0) {
    value = 2.0;
  }
  return Math.round(value * 100) / 100;
}

function clampVolume(value) {
  var volume = value;
  if (volume < 0) {
    volume = 0;
  }
  if (volume > 1) {
    volume = 1;
  }
  return Math.round(volume * 100) / 100;
}

function formatClock(ms) {
  if (!ms || ms < 0) {
    return "00:00";
  }

  var totalSeconds = Math.floor(ms / 1000);
  var minutes = Math.floor(totalSeconds / 60);
  var seconds = totalSeconds % 60;

  var minuteText = String(minutes);
  var secondText = seconds < 10 ? "0" + String(seconds) : String(seconds);
  return minuteText + ":" + secondText;
}
