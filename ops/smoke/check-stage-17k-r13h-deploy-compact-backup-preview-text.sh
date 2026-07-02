#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13h-deploy-compact-backup-preview-text.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13h-deploy-compact-backup-preview-text"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js"
ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-access.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Compact Backup Preview Text" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "Text formatting only" "$DOC"

grep -Fq "stage17k-r13h-compact-backup-preview-text-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_COMPACT_PREVIEW_TEXT_R13H" "$BRIDGE"
grep -Fq "Merge plan summary" "$BRIDGE"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_COMPACT_PREVIEW_TEXT_R13H" "$ADAPTER"
grep -Fq "Preview only. No data was restored, merged, or overwritten." "$ADAPTER"

grep -Fq "R13H_VM200_COMPACT_BACKUP_PREVIEW_TEXT_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13H smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13h deploy compact backup preview text smoke"
