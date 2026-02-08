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

if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  echo "Run: systemctl --user restart plasma-plasmashell.service"
elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart >/dev/null 2>&1; then
  echo "Run: kquitapp6 plasmashell && kstart plasmashell"
elif command -v plasmashell >/dev/null 2>&1; then
  echo "Run: kquitapp6 plasmashell && plasmashell --replace &"
else
  echo "Please restart Plasma shell manually."
fi
