# Quran Player — KDE Plasma 6 Widget

Audio-first Quran player plasmoid for KDE Plasma 6.

![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue)
![License](https://img.shields.io/badge/License-GPL--3.0-green)

## Features

- **Playback modes** — Ayah range queue or full-surah single-stream
- **Curated reciters** — Offline fallback + online refresh via Quran.com API
- **Transport controls** — Play/pause, next/prev, seek, speed (0.5×–2×), volume
- **Advanced controls** — A-B loop, per-ayah repeat, sleep timer
- **Bookmarks & presets** — Persistent across sessions
- **Panel mini-player** — Compact panel widget with circular progress indicator
- **Desktop full-player** — Expandable popup with tabbed UI (Player / Library / Settings)
- **MPRIS integration** — Optional media keys support via D-Bus (requires C++ plugin)
- **Theme-aware** — Automatically matches your Plasma color scheme

## Installation

### From source (Arch Linux)

```bash
git clone https://github.com/mymuhyo/kde-widget-quran.git
cd kde-widget-quran
./scripts/install-local.sh
systemctl --user restart plasma-plasmashell.service
```

### Arch Linux package

```bash
cd packaging
makepkg -si
```

### Optional: MPRIS plugin (media keys)

```bash
./scripts/build-plugin.sh
# Requires: cmake, qt6-base, qt6-declarative
```

## Project Structure

```
├── metadata.json                    # Plasmoid metadata
├── contents/
│   ├── ui/
│   │   ├── main.qml                # Entry point
│   │   ├── views/
│   │   │   ├── DesktopExpanded.qml  # Full player popup
│   │   │   └── PanelCompact.qml     # Panel mini-player
│   │   ├── models/
│   │   │   ├── PlaybackManager.qml  # App state & logic (singleton)
│   │   │   └── QueueModel.qml       # Playback queue
│   │   ├── components/              # Reusable UI components
│   │   └── config/                  # Settings UI
│   └── js/
│       ├── services/                # Business logic
│       │   ├── PlaybackController.js
│       │   ├── ProviderQuranCom.js
│       │   └── Storage.js
│       └── data/                    # Static data
│           ├── SurahMeta.js
│           └── CuratedReciters.js
├── plugin/                          # C++ MPRIS plugin (optional)
├── scripts/                         # Build & install scripts
├── packaging/                       # Arch Linux PKGBUILD
└── translations/                    # i18n files
```

## Development

```bash
# Validate project structure & lint QML
./scripts/smoke-check.sh

# Build .plasmoid package
./scripts/build.sh

# Install locally & restart Plasma
./scripts/install-local.sh
systemctl --user restart plasma-plasmashell.service
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Space` | Play / Pause |
| `Ctrl+→` | Next track |
| `Ctrl+←` | Previous track |
| `Ctrl+↑` | Speed up |
| `Ctrl+↓` | Speed down |
| `Ctrl+B` | Add bookmark |

## License

GPL-3.0-or-later
