#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8m-readonly-live-email-env-inventory.md"
RAW_OUT="docs/generated/stage-17k-z-r8m-readonly-live-email-env-inventory.txt"
JSON_OUT="docs/generated/stage-17k-z-r8m-readonly-live-email-env-inventory.json"

echo "=== Stage 17K-Z-R8M-R2 read-only env inventory smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8M-R2" "$DOC"
grep -Fq "no-reply@buddieswhostudy.com" "$DOC"
grep -Fq "Live CT203 env inventory did not complete" "$DOC"
grep -Fq "does not print provider keys" "$DOC"

grep -Fq "expected_email_from=no-reply@buddieswhostudy.com" "$RAW_OUT"
grep -Fq "PUBLIC_BASE_URL=https://buddieswhostudy.com" "$RAW_OUT"
grep -Fq "EMAIL_FROM=no-reply@buddieswhostudy.com" "$RAW_OUT"
grep -Fq "pvew_or_ct203_env_inventory=failed_or_timed_out" "$RAW_OUT"
grep -Fq "HTTP/2 200" "$RAW_OUT"
grep -Fq "HTTP/2 301" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8M-R2"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"secrets_printed": false' "$JSON_OUT"
grep -Fq '"repo_defaults_updated": true' "$JSON_OUT"
grep -Fq '"live_env_inventory_available": false' "$JSON_OUT"
grep -Fq '"pvew_or_ct203_inventory_failed_or_timed_out": true' "$JSON_OUT"
grep -Fq '"live_env_mentions_old_sender": false' "$JSON_OUT"
grep -Fq '"live_env_mentions_new_sender": false' "$JSON_OUT"
grep -Fq '"expected_email_from": "no-reply@buddieswhostudy.com"' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8M-R2 read-only env inventory smoke"
