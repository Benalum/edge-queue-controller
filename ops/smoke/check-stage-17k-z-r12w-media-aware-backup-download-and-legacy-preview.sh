#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12w-media-aware-backup-download-and-legacy-preview.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12w-media-aware-backup-download-and-legacy-preview"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
RESTORE="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Media-Aware Backup Download and Legacy Preview" "$DOC"
grep -Fq "study/media/v1" "$DOC"
grep -Fq "old v1 backup files" "$DOC"
grep -Fq "No restore write path" "$DOC"

grep -Fq "stage17k-z-r12w-media-aware-backup-legacy-preview-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MEDIA_AWARE_EXPORT_R12W" "$PANEL"
grep -Fq "study/media-manifest/v1" "$PANEL"
grep -Fq "buddies-who-study-local-backup-v2-" "$PANEL"
grep -Fq "APC_LOCAL_BACKUP_RESTORE_PREVIEW_LEGACY_V1_COMPAT_R12W" "$RESTORE"
grep -Fq "normalizePrivacyR12W" "$RESTORE"

grep -Fq "R12W_VM200_MEDIA_AWARE_BACKUP_LEGACY_PREVIEW_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12W smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12w media-aware backup download legacy preview smoke"
