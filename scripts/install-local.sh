#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if command -v kpackagetool6 >/dev/null 2>&1; then
  KPKG_TOOL="kpackagetool6"
elif command -v kpackagetool5 >/dev/null 2>&1; then
  KPKG_TOOL="kpackagetool5"
else
  echo "Neither kpackagetool6 nor kpackagetool5 was found in PATH."
  exit 1
fi

cp -r "$ROOT_DIR/metadata.json" "$ROOT_DIR/contents" "$ROOT_DIR/translations" "$TMP_DIR/"

if "$KPKG_TOOL" --type Plasma/Applet --upgrade "$TMP_DIR" >/dev/null 2>&1; then
  echo "Upgraded plasmoid from $ROOT_DIR"
else
  "$KPKG_TOOL" --type Plasma/Applet --install "$TMP_DIR"
  echo "Installed plasmoid from $ROOT_DIR"
fi

if [[ "${QURAN_WIDGET_SKIP_RESTART:-0}" == "1" ]]; then
  echo "Skipping plasmashell restart (QURAN_WIDGET_SKIP_RESTART=1)."
  exit 0
fi

echo "Applying changes: restarting Plasma shell..."
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
  echo "Plasma shell restarted via systemd user service."
elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
  sleep 0.4
  kstart plasmashell >/dev/null 2>&1 &
  echo "Plasma shell restarted via kquitapp6 + kstart."
elif command -v plasmashell >/dev/null 2>&1 && command -v kquitapp6 >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
  sleep 0.4
  plasmashell --replace >/dev/null 2>&1 &
  echo "Plasma shell restarted via plasmashell --replace."
else
  echo "Could not auto-restart plasmashell. Please restart manually."
fi

# Safety net: if restart path failed to bring shell back, try once more.
sleep 1
if ! pgrep -x plasmashell >/dev/null 2>&1; then
  echo "Plasma shell is not running; attempting recovery start..."
  if command -v kstart >/dev/null 2>&1; then
    kstart plasmashell >/dev/null 2>&1 &
    sleep 1
  fi
fi

if pgrep -x plasmashell >/dev/null 2>&1; then
  echo "Plasma shell is running."
else
  echo "Recovery start failed. Run: kstart plasmashell"
fi
