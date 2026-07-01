#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11j-r2-vm200-static-deploy-profile-anki-preview-cachebust-fix.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11j-r2-vm200-static-deploy-profile-anki-preview-cachebust-fix"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Controlled VM200 static frontend deploy repair checkpoint" "$DOC"
grep -q "pre-probed cache-bust URL" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No signup change" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"
grep -q "No service restart" "$DOC"

test -f "$OUT_DIR/vm200-deploy."*.txt
test -f "$OUT_DIR/vm200-local-http-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-static-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

grep -q "R11J_R2_VM200_STATIC_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -q "PASS VM200 local HTTP script smoke" "$OUT_DIR/vm200-local-http-smoke."*.txt
grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "api_system_status=200" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "api_me_status=401" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "signup_status=403" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r11j-r2 VM200 static deploy Profile Anki preview cache-bust fix smoke"
