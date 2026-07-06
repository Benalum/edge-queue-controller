#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14c-record-executor-loaded-no-ui-no-write-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14c-record-executor-loaded-no-ui-no-write-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Executor Loaded No UI/Write Binding Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R14B_EXECUTOR_LOADED_NO_UI_NO_WRITE_BINDING" "$DOC"
grep -Fq "executorLoadedByScript true" "$DOC"
grep -Fq "executorWindowPresent true" "$DOC"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY" "$DOC"
grep -Fq "hasExecuteFunction true" "$DOC"
grep -Fq "savePlanPreviewStillVisible true" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"
grep -Fq "Choose local backup folder" "$DOC"
grep -Fq "Download snapshot" "$DOC"
grep -Fq "Preview backup file" "$DOC"
grep -Fq "Open current backup file" "$DOC"
grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "mountReferencesExecutor false" "$DOC"
grep -Fq "panelReferencesExecutor false" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r14c record executor loaded no ui no write proof smoke"
