#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13y-deploy-write-executor-asset-not-loaded.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13y-deploy-write-executor-asset-not-loaded"
EXECUTOR="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Write Executor Asset, Not Loaded" "$DOC"
grep -Fq "Asset-only deploy" "$DOC"
grep -Fq "No index load" "$DOC"
grep -Fq "No Profile integration" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY" "$EXECUTOR"
grep -Fq "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE" "$EXECUTOR"
grep -Fq "executeCurrentBackupWrite" "$EXECUTOR"

if grep -Fq "/privatepages/local-backup-current-file-write-executor.js" "$INDEX"; then
  echo "FAIL: executor loaded by index"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR" "$MOUNT" "$PANEL"; then
  echo "FAIL: executor referenced by live Profile source"
  exit 1
fi

grep -Fq "R13Y_VM200_WRITE_EXECUTOR_ASSET_NOT_LOADED_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13Y asset smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13y deploy write executor asset not loaded smoke"
