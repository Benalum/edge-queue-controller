#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13q-r7-fix-download-get-panel-api.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13q-r7-fix-download-get-panel-api"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Fix Download Snapshot getPanelApi" "$DOC"
grep -Fq "ReferenceError: getPanelApi is not defined" "$DOC"
grep -Fq "No same-file write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

grep -Fq "stage17k-r13q-r7-fix-download-get-panel-api-20260705" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_GET_PANEL_API_FIX_R13Q_R7" "$MOUNT"
grep -Fq "function getPanelApi()" "$MOUNT"
grep -Fq "root.APC_PROFILE_LOCAL_BACKUPS_PANEL" "$MOUNT"

grep -Fq "R13Q_R7_VM200_FIX_DOWNLOAD_GET_PANEL_API_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13Q-R7 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13q-r7 fix download getPanelApi smoke"
