#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8q-live-email-env-patch-ct203.md"
RAW_OUT="docs/generated/stage-17k-z-r8q-live-email-env-patch-ct203.txt"
JSON_OUT="docs/generated/stage-17k-z-r8q-live-email-env-patch-ct203.json"

echo "=== Stage 17K-Z-R8Q live email env patch smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8Q" "$DOC"
grep -Fq "EMAIL_FROM=no-reply@buddieswhostudy.com" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"

grep -Fq "backup_file=" "$RAW_OUT"
grep -Fq "PASS_CT203_R8Q_EMAIL_ENV_PATCH_ACTIVE" "$RAW_OUT"
grep -Fq "PUBLIC_BASE_URL=https://buddieswhostudy.com" "$RAW_OUT"
grep -Fq "EMAIL_FROM=no-reply@buddieswhostudy.com" "$RAW_OUT"
grep -Fq "EMAIL_FROM_NAME=Buddies Who Study" "$RAW_OUT"
grep -Fq "register_http=403" "$RAW_OUT"
grep -Fq "closed_beta_signup_disabled" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8Q"' "$JSON_OUT"
grep -Fq '"live_env_mutation": true' "$JSON_OUT"
grep -Fq '"secrets_printed": false' "$JSON_OUT"
grep -Fq '"controller_restart_performed": true' "$JSON_OUT"
grep -Fq '"active_env_has_new_sender": true' "$JSON_OUT"
grep -Fq '"old_sender_absent_from_active_env": true' "$JSON_OUT"
grep -Fq '"register_gate_403_preserved": true' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8Q live email env patch smoke"
