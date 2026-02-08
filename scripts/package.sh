#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

VERSION="$(sed -n 's/.*"Version": "\([^"]*\)".*/\1/p' "$ROOT_DIR/metadata.json" | head -n1)"
SOURCE_ARCHIVE="$BUILD_DIR/kde-widget-quran-${VERSION}.tar.gz"

rm -f "$SOURCE_ARCHIVE"

tar \
  --exclude-vcs \
  --exclude='build' \
  -C "$ROOT_DIR" \
  -czf "$SOURCE_ARCHIVE" \
  .

echo "Created source archive: $SOURCE_ARCHIVE"
