#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13n-deploy-sanitized-payload-preview-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13n-deploy-sanitized-payload-preview-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Sanitized Payload Preview Only" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No Download snapshot behavior change" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No save/write/overwrite helper" "$DOC"

grep -Fq "stage17k-r13n-sanitized-payload-preview-only-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SANITIZED_PAYLOAD_PREVIEW_BIND_R13N" "$MOUNT"
grep -Fq "Sanitized payload preview only. The cleaned backup payload was not saved anywhere." "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER_R13M_SOURCE_ONLY" "$BUILDER"

grep -Fq "R13N_VM200_SANITIZED_PAYLOAD_PREVIEW_ONLY_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13N smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13n deploy sanitized payload preview only smoke"
