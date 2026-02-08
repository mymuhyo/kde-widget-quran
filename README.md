# KDE Plasma Quran Player Widget

Audio-first Quran player plasmoid for KDE Plasma 6 (Arch Linux friendly).

## Current Features
- Surah + ayah range queue playback
- Full-surah single-stream playback mode (when provider supports it)
- Curated reciters with Quran.com online refresh and fallback URLs
- Transport controls: play/pause, next/prev, seek, speed, volume
- Advanced controls: A-B loop, ayah repeat count, sleep timer
- Bookmarks and presets (persistent)
- Adaptive panel mini-player + desktop full-player
- Opt-in analytics toggle (disabled by default)

## Local Development
```bash
./scripts/smoke-check.sh
./scripts/build.sh
./scripts/install-local.sh
systemctl --user restart plasma-plasmashell.service
```

## Packaging (Arch)
```bash
cd packaging
makepkg -si
```

## CI
GitHub Actions workflow: `.github/workflows/ci.yml`
- Shellcheck for scripts
- Project smoke checks

## Notes
- Primary provider: Quran.com API
- Fallback audio templates are included for resilience
- Main script path is `contents/ui/main.qml`
