#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13d-deploy-stable-current-backup-preview-wording.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13d-deploy-stable-current-backup-preview-wording"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-stable-file-plan.js"
BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Stable Current Backup Preview Wording" "$DOC"
grep -Fq "buddies-who-study-current.json" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

grep -Fq "stage17k-r13d-stable-current-backup-preview-wording-20260702" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_STABLE_FILE_PLAN_R13C_SOURCE_ONLY" "$PLAN"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_STABLE_FILE_PLAN_PREVIEW_R13D" "$BRIDGE"
grep -Fq "Backup file naming" "$BRIDGE"
grep -Fq "Normal file to keep using" "$BRIDGE"

grep -Fq "R13D_VM200_STABLE_CURRENT_BACKUP_PREVIEW_WORDING_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13D smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13d deploy stable current backup preview wording smoke"
