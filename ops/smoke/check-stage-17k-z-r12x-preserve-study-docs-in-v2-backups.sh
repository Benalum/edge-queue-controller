#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12x-preserve-study-docs-in-v2-backups.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12x-preserve-study-docs-in-v2-backups"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Preserve Study Docs in V2 Backups" "$DOC"
grep -Fq "study/cards/v1" "$DOC"
grep -Fq "study/media/v1" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"

grep -Fq "stage17k-z-r12x-preserve-study-docs-v2-backup-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_PRESERVE_STUDY_DOCS_R12X" "$PANEL"
grep -Fq "preserveStudyDocsInBackupPayloadR12X" "$PANEL"
grep -Fq "readLocalSavePrimaryDocsR12X" "$PANEL"

grep -Fq "R12X_VM200_PRESERVE_STUDY_DOCS_V2_BACKUP_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12X smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12x preserve Study docs in v2 backups smoke"
