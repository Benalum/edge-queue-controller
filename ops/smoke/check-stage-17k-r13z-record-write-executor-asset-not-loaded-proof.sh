#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13z-record-write-executor-asset-not-loaded-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13z-record-write-executor-asset-not-loaded-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Write Executor Asset-Not-Loaded Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R13Y_WRITE_EXECUTOR_ASSET_NOT_LOADED" "$DOC"
grep -Fq "executorAssetStatus 200" "$DOC"
grep -Fq "executorAssetHasMarker true" "$DOC"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY" "$DOC"
grep -Fq "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE" "$DOC"
grep -Fq "executeCurrentBackupWrite" "$DOC"
grep -Fq "executorLoadedByScript false" "$DOC"
grep -Fq "executorWindowPresent false" "$DOC"
grep -Fq "savePlanPreviewStillVisible true" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"
grep -Fq "Choose local backup folder" "$DOC"
grep -Fq "Download snapshot" "$DOC"
grep -Fq "Preview backup file" "$DOC"
grep -Fq "Open current backup file" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No current-file save" "$DOC"
grep -Fq "No same-file write path" "$DOC"

echo "PASS stage-17k-r13z record write executor asset-not-loaded proof smoke"
