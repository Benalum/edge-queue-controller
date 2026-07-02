#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12y-async-study-doc-export-and-merge-plan.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12y-async-study-doc-export-and-merge-plan"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Async Study Doc Export and Merge Plan" "$DOC"
grep -Fq "backup set, not endless snapshot files" "$DOC"
grep -Fq "Decks merge by id" "$DOC"
grep -Fq "R12Z" "$DOC"

grep -Fq "stage17k-z-r12y-async-study-doc-export-merge-plan-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_ASYNC_STUDY_DOC_EXPORT_R12Y" "$PANEL"
grep -Fq "readLocalSavePrimaryDocsAsyncR12Y" "$PANEL"
grep -Fq "preserveStudyDocsInBackupPayloadAsyncR12Y" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_ASYNC_DOWNLOAD_BIND_R12Y" "$MOUNT"
grep -Fq "Backup download ready. Study docs and media docs were included." "$MOUNT"

grep -Fq "R12Y_VM200_ASYNC_STUDY_DOC_EXPORT_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12Y smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12y async Study doc export and merge plan smoke"
