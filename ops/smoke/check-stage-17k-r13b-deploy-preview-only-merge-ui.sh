#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13b-deploy-preview-only-merge-ui.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13b-deploy-preview-only-merge-ui"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MERGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-merge-planner.js"
BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Preview-Only Merge UI" "$DOC"
grep -Fq "No Apply button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No Profile local backups panel change" "$DOC"

grep -Fq "stage17k-r13b-preview-only-merge-ui-20260702" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_MERGE_PLANNER_R12Z_SOURCE_ONLY" "$MERGE"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE_R13A_SOURCE_ONLY" "$BRIDGE"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_UI_BIND_R13B" "$MOUNT"
grep -Fq "Backup merge preview complete. No data was restored." "$MOUNT"

grep -Fq "R13B_VM200_PREVIEW_ONLY_MERGE_UI_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13B smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13b deploy preview-only merge UI smoke"
