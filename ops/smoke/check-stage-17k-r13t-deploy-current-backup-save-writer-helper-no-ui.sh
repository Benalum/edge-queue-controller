#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13t-deploy-current-backup-save-writer-helper-no-ui.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13t-deploy-current-backup-save-writer-helper-no-ui"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
HELPER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Current Backup Save Writer Helper, No UI" "$DOC"
grep -Fq "No visible UI change" "$DOC"
grep -Fq "No file write enabled" "$DOC"
grep -Fq "No same-file write path enabled" "$DOC"

grep -Fq "stage17k-r13t-current-backup-save-writer-helper-no-ui-20260705" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY" "$HELPER"
grep -Fq "sameFileWriteEnabled: false" "$HELPER"
grep -Fq "currentFileWriteEnabled: false" "$HELPER"
grep -Fq "previousFileWriteEnabled: false" "$HELPER"

grep -Fq "R13T_VM200_CURRENT_BACKUP_SAVE_WRITER_HELPER_NO_UI_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13T smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13t deploy current backup save writer helper no ui smoke"
