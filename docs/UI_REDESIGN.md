# Quran Player UI Redesign

## Goal

The widget should feel like a native KDE Plasma applet: clean, calm, readable, theme-aware, and practical. It should not look like a web music player, neon dashboard, or heavy custom skin.

## Design direction

- Native Plasma/Kirigami colors only.
- Soft cards, not glass/neon.
- Clear hierarchy: current listening state first, selection second, queue third.
- Minimal playback UI: play/pause, previous, next, bookmark, seek. No visible advanced playback tools.
- Arabic ayah text should feel sacred and calm: centered, readable, enough breathing room.
- Quick actions should be helpful but not visually loud.

## Layout sketch

Window: 560 × 760 preferred.

Top-level structure:

1. Now Playing card
   - Header: Quran Player + queue position chip
   - Current surah/ayah title
   - Reciter subtitle
   - Optional Uthmani ayah text panel
   - Seek bar + time labels
   - Minimal centered controls
   - Status banner only when loading/error/info is meaningful

2. Tab strip
   - Listen
   - Library
   - Settings

3. Listen tab
   - Quick Start card
     - Al-Fatihah
     - Al-Kahf
     - Ya-Sin
     - Al-Mulk
   - Recitation card
     - Reciter selector
     - Surah selector/search
     - Mode/range
     - Build Queue / Play Now
   - Queue card
     - Up Next list
     - Empty state with Build Queue / Play Now

4. Library tab
   - Presets card
   - Bookmarks card

5. Settings tab
   - Comfort card
   - Shortcuts card
   - Status card

## Visual rules

### Spacing

- Outer margin: 14 px
- Main vertical spacing: 12 px
- Card padding: 12–16 px
- Small internal spacing: 6–8 px

### Cards

Use existing `SurfaceCard.qml` style. Do not add strong gradients, glow, blur, or decorative circles.

### Typography

- App title: 20–22 px bold
- Current track: 17–19 px bold
- Arabic text: 24–28 px, centered
- Section header: 14–15 px bold
- Secondary text: 11–13 px

### Colors

Use `PlaybackManager` theme colors only:

- `colorCard`
- `colorBorder`
- `colorTextPrimary`
- `colorTextSecondary`
- `colorAccent`
- `colorSurfaceMuted`
- `colorErrorBg`
- `colorInfoBg`

## Removed from expanded UI

The following should not be visible in the main expanded UI:

- A-B loop controls
- Speed slider
- Volume slider
- Ayah repeat controls
- Repeat mode controls
- Sleep timer controls
- Analytics controls

These can remain internally/configurable later, but they should not dominate the primary UX.

## Acceptance

The redesign is accepted if:

- It passes `scripts/smoke-check.sh`.
- It looks native in Plasma light and dark themes.
- A new user can start listening in one or two clicks.
- The expanded UI is not visually noisy.
- The panel compact widget still works.
- Existing queue/bookmark/preset behavior remains functional.
