#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13q-r6-panel-api-sanitized-download-url-diff-guard.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13q-r6-panel-api-sanitized-download-url-diff-guard"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Panel API Sanitized Download URL Diff Guard" "$DOC"
grep -Fq "Browser download only" "$DOC"
grep -Fq "No same-file write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

grep -Fq "stage17k-r13q-r6-panel-api-sanitized-download-url-20260705" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_PANEL_SANITIZED_CREATE_DOWNLOAD_URL_R13Q_R6" "$PANEL"
grep -Fq "createDownloadUrlSanitizedR13QR6" "$PANEL"
grep -Fq "prepared.jsonText" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SANITIZED_DOWNLOAD_SNAPSHOT_R13Q_R4" "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT_HELPER_R13O_SOURCE_ONLY" "$SNAPSHOT"

grep -Fq "R13Q_R6_VM200_PANEL_API_SANITIZED_DOWNLOAD_URL_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13Q-R6 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13q-r6 panel api sanitized download url diff guard smoke"
