#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ANKI_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
GOOGLE_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
DOC="docs/stage-17k-z-r11q-remove-profile-google-indirect-loader-source-only.md"

test -f "$INDEX"
test -f "$ANKI_PANEL"
test -f "$GOOGLE_PANEL"
test -f "$DOC"

grep -q "/privatepages/profile-google-sync-panel.js?v=stage17k-z-r11q-profile-google-direct-loader-20260701" "$INDEX"
grep -q "/privatepages/anki-manifest-panel.js?v=stage17k-z-r11q-profile-google-direct-loader-20260701" "$INDEX"

if grep -q "APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_START" "$ANKI_PANEL"; then
  echo "FAIL: stale Google loader start marker remains in Anki panel"
  exit 1
fi

if grep -q "APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_END" "$ANKI_PANEL"; then
  echo "FAIL: stale Google loader end marker remains in Anki panel"
  exit 1
fi

if grep -q "apc-profile-google-sync-panel-script-stage-17k-z-r6c" "$ANKI_PANEL"; then
  echo "FAIL: stale Google loader script id remains in Anki panel"
  exit 1
fi

if grep -q "profile-google-sync-panel.js?v=20260629-stage17k-z-r7c-appdata" "$ANKI_PANEL"; then
  echo "FAIL: stale indirect Google module path remains in Anki panel"
  exit 1
fi

grep -q "R11Q removed legacy Profile Google sync indirect loader from Anki panel" "$ANKI_PANEL"
grep -q "apc-private-page-rendered" "$GOOGLE_PANEL"

if grep -q "apc:privatepage:rendered" "$GOOGLE_PANEL"; then
  echo "FAIL: stale colon private-page event remains in Google panel"
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
html = Path("frontend/wrapper-ui/apc-wrapper-local/index.html").read_text()
order = [
    "/privatepages/privatepages.js",
    "/privatepages/google-sync-config.js",
    "/privatepages/profile-google-sync-panel.js",
    "/privatepages/anki-manifest-panel.js",
]
positions = [html.index(item) for item in order]
if positions != sorted(positions):
    raise SystemExit(f"FAIL script order {positions}")
print("PASS script order: privatepages, google config, profile google panel, anki panel")
PY

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js; then
  echo "FAIL: forbidden broad Profile/session files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$ANKI_PANEL"
  node --check "$GOOGLE_PANEL"
fi

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "does not modify privatepages.js" "$DOC"
grep -q "does not modify the Profile fragment" "$DOC"
grep -q "does not change the session gate" "$DOC"
grep -q "does not alter the private shell" "$DOC"
grep -q "removes the duplicate indirect loader" "$DOC"

echo "PASS stage-17k-z-r11q remove Profile Google indirect loader source-only smoke"
