#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11k-live-browser-profile-anki-preview-proof-plan.md"

test -f "$DOC"

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

grep -q "APC_R11K_PROFILE_ANKI_BROWSER_PROOF" "$DOC"
grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$DOC"
grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" "$DOC"
grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" "$DOC"
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" "$DOC"
grep -q "pass true" "$DOC"

echo "PASS stage-17k-z-r11k live browser Profile Anki preview proof plan smoke"
