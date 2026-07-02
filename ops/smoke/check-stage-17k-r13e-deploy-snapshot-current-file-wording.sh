#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13e-deploy-snapshot-current-file-wording.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13e-deploy-snapshot-current-file-wording"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Snapshot / Current-File Backup Wording" "$DOC"
grep -Fq "Download snapshot" "$DOC"
grep -Fq "buddies-who-study-current.json" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

grep -Fq "stage17k-r13e-snapshot-current-file-wording-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SNAPSHOT_CURRENT_FILE_WORDING_R13E" "$PANEL"
grep -Fq "Download snapshot" "$PANEL"
grep -Fq "Download snapshots are timestamped safety copies." "$PANEL"
grep -Fq "buddies-who-study-current.json" "$PANEL"

grep -Fq "R13E_VM200_SNAPSHOT_CURRENT_FILE_WORDING_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13E smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13e deploy snapshot/current-file wording smoke"
