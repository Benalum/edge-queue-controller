#!/usr/bin/env bash
set -euo pipefail

SMOKE_E="ops/smoke/check-stage-17k-z-r11e-profile-anki-apkg-preview-bridge-no-ui.sh"
SMOKE_F="ops/smoke/check-stage-17k-z-r11f-profile-anki-apkg-preview-panel-source-no-mount.sh"
SMOKE_G="ops/smoke/check-stage-17k-z-r11g-profile-anki-preview-source-mount-no-deploy.sh"
DOC="docs/stage-17k-z-r11g-r2-repair-superseded-profile-anki-mount-smokes.md"

test -f "$SMOKE_E"
test -f "$SMOKE_F"
test -f "$SMOKE_G"
test -f "$DOC"

grep -q "R11G source mount supersedes" "$SMOKE_E"
grep -q "R11G source mount supersedes" "$SMOKE_F"
grep -q "profile-anki-preview-mount.js" frontend/wrapper-ui/apc-wrapper-local/index.html
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

echo "PASS stage-17k-z-r11g-r2 superseded Profile Anki mount smoke repair"
