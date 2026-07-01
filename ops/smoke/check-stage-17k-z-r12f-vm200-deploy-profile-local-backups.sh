#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12f-vm200-deploy-profile-local-backups.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12f-vm200-deploy-profile-local-backups"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Only three files were deployed" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "profile-local-backups-panel.js?v=stage17k-z-r12f-profile-local-backups-20260701" "$INDEX"
grep -Fq "profile-local-backups-mount.js?v=stage17k-z-r12f-profile-local-backups-20260701" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_PANEL_R12D_SOURCE_ONLY" "$PANEL"
grep -Fq "Buddies Who Study local backups" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY" "$MOUNT"
grep -Fq "mountFromPrivateProfileEvent" "$MOUNT"
grep -Fq "R12F_VM200_THREE_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12F smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12f VM200 deploy Profile local backups smoke"
