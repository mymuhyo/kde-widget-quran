#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

PLUGIN_ID="$(sed -n 's/.*"Id": "\([^"]*\)".*/\1/p' "$ROOT_DIR/metadata.json" | head -n1)"
VERSION="$(sed -n 's/.*"Version": "\([^"]*\)".*/\1/p' "$ROOT_DIR/metadata.json" | head -n1)"
ARCHIVE_PATH="$BUILD_DIR/${PLUGIN_ID}-${VERSION}.plasmoid"

if command -v zip >/dev/null 2>&1; then
  rm -f "$ARCHIVE_PATH"
  (
    cd "$ROOT_DIR"
    zip -r "$ARCHIVE_PATH" metadata.json contents translations README.md >/dev/null
  )
  echo "Built package: $ARCHIVE_PATH"
else
  ARCHIVE_PATH="$BUILD_DIR/${PLUGIN_ID}-${VERSION}.tar.gz"
  rm -f "$ARCHIVE_PATH"
  (
    cd "$ROOT_DIR"
    tar -czf "$ARCHIVE_PATH" metadata.json contents translations README.md
  )
  echo "zip was not found; built tarball instead: $ARCHIVE_PATH"
fi
