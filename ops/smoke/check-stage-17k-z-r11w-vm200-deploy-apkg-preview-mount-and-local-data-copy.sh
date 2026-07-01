#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11w-vm200-deploy-apkg-preview-mount-and-local-data-copy.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11w-vm200-deploy-apkg-preview-mount-and-local-data-copy"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Controlled narrow VM200 static frontend deploy checkpoint" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No bandage" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Profile fragment change" "$DOC"
grep -Fq "No session gate change" "$DOC"
grep -Fq "No private shell change" "$DOC"
grep -Fq "No backend route addition" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "Only these three files were deployed" "$DOC"

grep -Fq "profile-google-sync-panel.js?v=stage17k-z-r11w-apkg-preview-local-data-copy-20260701" "$INDEX"
grep -Fq "profile-anki-preview-mount.js?v=stage17k-z-r11w-apkg-preview-local-data-copy-20260701" "$INDEX"
grep -Fq "APC_PROFILE_ANKI_PREVIEW_MOUNT_STABLE_PROFILE_DOM_R11U" "$MOUNT"
grep -Fq "Buddies Who Study local data" "$GOOGLE"

test -f "$OUT_DIR/vm200-deploy."*.txt
test -f "$OUT_DIR/vm200-local-http-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-static-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

grep -Fq "R11W_VM200_THREE_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS VM200 local R11W static smoke" "$OUT_DIR/vm200-local-http-smoke."*.txt
grep -Fq "APC_PROFILE_ANKI_PREVIEW_MOUNT_STABLE_PROFILE_DOM_R11U" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -Fq "Buddies Who Study local data" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r11w VM200 deploy APKG preview mount and local data copy smoke"
