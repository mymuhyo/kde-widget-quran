.pragma library

var _enabled = false;
var _events = [];

function setEnabled(enabled) {
  _enabled = !!enabled;
}

function enabled() {
  return _enabled;
}

function track(eventName, payload) {
  if (!_enabled) {
    return;
  }

  _events.push({
    eventName: eventName,
    payload: payload || {},
    timestamp: new Date().toISOString()
  });

  if (_events.length > 200) {
    _events.shift();
  }
}

function events() {
  return _events.slice();
}
