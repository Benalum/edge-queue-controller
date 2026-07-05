#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13q-r4-deploy-sanitized-download-snapshot-exact-handler.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13q-r4-deploy-sanitized-download-snapshot-exact-handler"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Sanitized Download Snapshot Exact Handler" "$DOC"
grep -Fq "Browser download only" "$DOC"
grep -Fq "No same-file write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

grep -Fq "stage17k-r13q-r4-sanitized-download-snapshot-20260705" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SANITIZED_DOWNLOAD_SNAPSHOT_R13Q_R4" "$MOUNT"
grep -Fq "sanitizedSnapshotOutputR13QR4.jsonText" "$MOUNT"
grep -Fq "sanitizedSnapshotOutputR13QR4.fileName" "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT_HELPER_R13O_SOURCE_ONLY" "$SNAPSHOT"

if grep -Fq "const url = panelApi.createDownloadUrl(payload);" "$MOUNT"; then
  echo "FAIL: legacy R12Y createDownloadUrl(payload) remains"
  exit 1
fi

if grep -Fq "link.download = panelApi.backupFileName(payload && payload.createdAt);" "$MOUNT"; then
  echo "FAIL: legacy R12Y filename remains"
  exit 1
fi

grep -Fq "R13Q_R4_VM200_SANITIZED_DOWNLOAD_SNAPSHOT_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13Q-R4 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13q-r4 deploy sanitized download snapshot exact handler smoke"
