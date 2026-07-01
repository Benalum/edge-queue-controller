#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
SRC_IMPORT="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
SRC_BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js"
SRC_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js"
SRC_MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js"
DOC="docs/stage-17k-z-r11h-profile-anki-preview-deploy-readiness-no-deploy.md"

test -f "$INDEX"
test -f "$SRC_IMPORT"
test -f "$SRC_BRIDGE"
test -f "$SRC_PANEL"
test -f "$SRC_MOUNT"
test -f "$DOC"

grep -q "APC_ANKI_IMPORT_LOCAL_DISABLED_SKELETON_R11B" "$SRC_IMPORT"
grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$SRC_IMPORT"
grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" "$SRC_BRIDGE"
grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" "$SRC_PANEL"
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" "$SRC_MOUNT"

grep -q "/privatepages/anki-import-local.js" "$INDEX"
grep -q "/privatepages/profile-anki-import-bridge.js" "$INDEX"
grep -q "/privatepages/profile-anki-preview-panel.js" "$INDEX"
grep -q "/privatepages/profile-anki-preview-mount.js" "$INDEX"

python3 - <<'PY'
from pathlib import Path
html = Path("frontend/wrapper-ui/apc-wrapper-local/index.html").read_text()
order = [
    "/privatepages/anki-import-local.js",
    "/privatepages/profile-anki-import-bridge.js",
    "/privatepages/profile-anki-preview-panel.js",
    "/privatepages/profile-anki-preview-mount.js",
]
positions = [html.index(item) for item in order]
if positions != sorted(positions):
    raise SystemExit(f"FAIL script order: {positions}")
print("PASS Profile Anki script order")
PY

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

for src in "$SRC_IMPORT" "$SRC_BRIDGE" "$SRC_PANEL" "$SRC_MOUNT"; do
  if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$src"; then
    echo "FAIL: forbidden network/backend/persistence write in $src"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$SRC_IMPORT"
  node --check "$SRC_BRIDGE"
  node --check "$SRC_PANEL"
  node --check "$SRC_MOUNT"
fi

echo "PASS stage-17k-z-r11h profile anki preview deploy-readiness smoke"
