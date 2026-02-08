#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REQUIRED_FILES=(
  "metadata.json"
  "contents/ui/main.qml"
  "contents/ui/views/DesktopExpanded.qml"
  "contents/ui/views/PanelCompact.qml"
  "contents/js/services/ProviderQuranCom.js"
  "contents/js/services/Storage.js"
  "contents/js/services/PlaybackController.js"
  "packaging/PKGBUILD"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

python3 - <<'PY'
import json
from pathlib import Path

metadata = json.loads(Path("metadata.json").read_text(encoding="utf-8"))
plugin = metadata.get("KPlugin", {})
required = ["Id", "Name", "Version", "License"]
missing = [k for k in required if not plugin.get(k)]
if missing:
    raise SystemExit(f"metadata.json missing fields: {missing}")
if metadata.get("X-Plasma-MainScript") != "ui/main.qml":
    raise SystemExit("X-Plasma-MainScript must be ui/main.qml")
print("metadata.json: OK")
PY

bash -n scripts/build.sh scripts/install-local.sh scripts/package.sh scripts/smoke-check.sh
bash -n packaging/PKGBUILD

if command -v qmllint >/dev/null 2>&1; then
  qmllint contents/ui/main.qml contents/ui/components/*.qml contents/ui/views/*.qml
  echo "qmllint: OK"
else
  echo "qmllint: skipped (not installed)"
fi

./scripts/build.sh >/dev/null
./scripts/package.sh >/dev/null

echo "smoke-check: PASS"
