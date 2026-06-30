#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8p-readonly-live-email-env-after-vpn-off.md"
RAW_OUT="docs/generated/stage-17k-z-r8p-readonly-live-email-env-after-vpn-off.txt"
JSON_OUT="docs/generated/stage-17k-z-r8p-readonly-live-email-env-after-vpn-off.json"

echo "=== Stage 17K-Z-R8P read-only live email env smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8P" "$DOC"
grep -Fq "no-reply@buddieswhostudy.com" "$DOC"
grep -Fq "does not print provider keys" "$DOC"

grep -Fq "expected_email_from=no-reply@buddieswhostudy.com" "$RAW_OUT"
grep -Fq "repo defaults" "$RAW_OUT"
grep -Fq "public route still healthy" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8P"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"secrets_printed": false' "$JSON_OUT"
grep -Fq '"expected_email_from": "no-reply@buddieswhostudy.com"' "$JSON_OUT"
grep -Fq '"live_env_inventory_available":' "$JSON_OUT"
grep -Fq '"recommended_next_stage":' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8P read-only live email env smoke"
