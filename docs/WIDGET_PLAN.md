# Quran Player Widget — Review, Product Plan, and Implementation Roadmap

## Current project review

This project is a KDE Plasma 6 plasmoid focused on Quran audio playback. It already has a strong base:

- QML widget shell with separate compact panel and expanded desktop/popup views.
- Playback state managed through `PlaybackManager.qml`.
- Queue management through `QueueModel.qml`.
- Quran.com provider integration with curated offline/fallback reciters.
- LocalStorage persistence for settings, bookmarks, and presets.
- Optional C++ MPRIS plugin for media-key integration.
- Theme-aware colors using Plasma/Kirigami palette values.
- Existing support for range playback, full-surah playback, bookmarks, presets, speed, volume, A-B loop, ayah repeat, sleep timer, and status/retry handling.

The main opportunity is not a full rewrite. The architecture is already useful. The best next step is to make the available capability easier to discover, more readable, more resilient in panel layouts, and more polished visually.

## Product vision

Build a beautiful, fast, and calm Quran listening widget that feels native in KDE Plasma:

1. One-click listening from the panel.
2. Clear expanded view for choosing reciter, surah, ayah range, repeat style, speed, and sleep timer.
3. Readable current-track and queue labels using surah names, not only numbers.
4. Graceful fallback when the network or Quran.com provider is unavailable.
5. Accessible interaction: keyboard shortcuts, tooltips, focus rings, readable text, and responsive layouts.
6. Native Plasma behavior: theme-aware design, compact panel mode, desktop mode, and optional MPRIS/media keys.

## UX priorities

### Must be immediate

- Panel compact mode should always fit horizontal and vertical panels.
- Play/pause should work without opening the full widget.
- Expanded player should show current reciter, current surah/ayah, progress, and primary controls first.
- If no queue exists, pressing play should build and start the configured queue.

### Must be discoverable

- Advanced features such as repeat, ayah repeat, A-B loop, speed, volume, and sleep timer must be visible in the Player tab.
- Keyboard shortcuts should be documented inside the widget.
- Queue, bookmarks, and presets should use readable labels.

### Must be trustworthy

- Loading states need delayed spinners to avoid flicker.
- Slow network states need clear messages.
- Errors need retry/fallback actions.
- Offline or degraded operation should not feel broken.

## Implemented in this pass

- Added localized surah-label helpers to `PlaybackManager.qml`.
- Updated current-track labels to show readable surah names.
- Updated queue items to show readable surah names and reciter subtitles when present.
- Updated MPRIS metadata to use the same readable track label as the UI.
- Exposed existing advanced playback tools in the Player tab through a new `Playback Tools` card.
- Replaced the unavailable analytics card with useful shortcut guidance.
- Improved compact panel sizing for vertical Plasma panels.

## Roadmap

### Phase 1 — Usability polish

- Add empty-state actions to the queue card: `Build Queue` and `Play Now`.
- Add a visible current queue position indicator such as `3 / 12` near the Now Playing card.
- Add favorite quick presets like Al-Fatihah, Al-Kahf, Ya-Sin, Al-Mulk, and Juz Amma.
- Make surah search non-destructive: typing should filter or suggest first, not instantly jump on every keystroke.
- Add stronger accessible names to all icon-only buttons.

### Phase 2 — Visual polish

- Refine card spacing and typography for 420–620 px popup widths.
- Add a subtle animated playing indicator in Now Playing and Queue.
- Add progress/provenance details while building longer ayah queues.
- Use Kirigami/Plasma-native icon rendering where possible instead of custom shader overlays.
- Audit light and dark theme contrast.

### Phase 3 — Reliability

- Cache fetched Uthmani ayah text to reduce repeated network calls.
- Persist last queue and current position so the widget can resume faster after Plasma restart.
- Add provider health states: online, degraded fallback, offline curated only.
- Add clearer validation for invalid ranges and unavailable reciter streams.
- Add tests for range normalization, queue index behavior, and provider fallback behavior.

### Phase 4 — Packaging and release quality

- Run translation extraction after UI text changes.
- Fix malformed translation catalog entries if present.
- Add screenshots/GIFs to the README.
- Document optional MPRIS plugin dependencies and behavior.
- Add release checklist for smoke check, packaging, local install, and Plasma restart.

## Acceptance checklist

The widget should be considered release-ready when:

- It passes `scripts/smoke-check.sh` on a Plasma 6 development system.
- It remains usable in horizontal panel, vertical panel, desktop, and popup modes.
- All core interactions are reachable by mouse and keyboard.
- Queue building works for curated fallback reciters and online Quran.com reciters.
- Provider errors show clear retry/fallback actions.
- Current track, queue, bookmarks, presets, and MPRIS all use human-readable labels.
- No unavailable feature is presented as active functionality.
