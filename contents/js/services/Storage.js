.pragma library

.import QtQuick.LocalStorage 2.0 as Sql

var DB_NAME = "quran_player_widget";
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Quran player settings";
var DB_ESTIMATED_SIZE = 2 * 1024 * 1024;

function _db() {
  return Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_ESTIMATED_SIZE);
}

function initialize() {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS bookmarks (id TEXT PRIMARY KEY, payload TEXT NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS presets (id TEXT PRIMARY KEY, payload TEXT NOT NULL)");
  });
}

function setSetting(key, value) {
  var db = _db();
  var payload = JSON.stringify(value);
  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO settings(key, value) VALUES (?, ?)", [key, payload]);
  });
}

function getSetting(key, fallbackValue) {
  var db = _db();
  var result = fallbackValue;

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT value FROM settings WHERE key = ?", [key]);
    if (rows.rows.length > 0) {
      try {
        result = JSON.parse(rows.rows.item(0).value);
      } catch (error) {
        result = fallbackValue;
      }
    }
  });

  return result;
}

function _createId(prefix) {
  return prefix + ":" + Date.now() + ":" + Math.floor(Math.random() * 1000000);
}

function saveBookmark(bookmark) {
  var db = _db();
  var item = bookmark || {};

  if (!item.id) {
    item.id = _createId("bookmark");
  }
  if (!item.createdAt) {
    item.createdAt = new Date().toISOString();
  }

  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO bookmarks(id, payload) VALUES (?, ?)", [item.id, JSON.stringify(item)]);
  });

  return item;
}

function removeBookmark(id) {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM bookmarks WHERE id = ?", [id]);
  });
}

function listBookmarks() {
  var db = _db();
  var list = [];

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT payload FROM bookmarks ORDER BY id DESC");
    for (var i = 0; i < rows.rows.length; i += 1) {
      try {
        list.push(JSON.parse(rows.rows.item(i).payload));
      } catch (error) {
        // Skip corrupted rows.
      }
    }
  });

  return list;
}

function savePreset(preset) {
  var db = _db();
  var item = preset || {};

  if (!item.id) {
    item.id = _createId("preset");
  }
  if (!item.createdAt) {
    item.createdAt = new Date().toISOString();
  }

  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO presets(id, payload) VALUES (?, ?)", [item.id, JSON.stringify(item)]);
  });

  return item;
}

function removePreset(id) {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM presets WHERE id = ?", [id]);
  });
}

function listPresets() {
  var db = _db();
  var list = [];

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT payload FROM presets ORDER BY id DESC");
    for (var i = 0; i < rows.rows.length; i += 1) {
      try {
        list.push(JSON.parse(rows.rows.item(i).payload));
      } catch (error) {
        // Skip corrupted rows.
      }
    }
  });

  return list;
}
