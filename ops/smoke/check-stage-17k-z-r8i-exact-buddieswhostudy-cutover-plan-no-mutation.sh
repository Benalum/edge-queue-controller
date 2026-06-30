#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8i-exact-buddieswhostudy-cutover-plan-no-mutation.md"
JSON_OUT="docs/generated/stage-17k-z-r8i-exact-buddieswhostudy-cutover-plan-no-mutation.json"

echo "=== Stage 17K-Z-R8I exact cutover plan smoke ==="

test -f "$DOC"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8I" "$DOC"
grep -Fq "buddieswhostudy.com" "$DOC"
grep -Fq "www.buddieswhostudy.com" "$DOC"
grep -Fq "alexhartel.com" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$DOC"
grep -Fq "R8J" "$DOC"
grep -Fq "R8K" "$DOC"
grep -Fq "R8M" "$DOC"
grep -Fq "SPF" "$DOC"
grep -Fq "DKIM" "$DOC"
grep -Fq "DMARC" "$DOC"
grep -Fq "Do not proceed to R8K mutation" "$DOC"

grep -Fq '"stage": "17K-Z-R8I"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"go_for_r8j_read_only": true' "$JSON_OUT"
grep -Fq '"go_for_r8k_mutation_now": false' "$JSON_OUT"
grep -Fq '"https://buddieswhostudy.com"' "$JSON_OUT"
grep -Fq '"https://www.buddieswhostudy.com"' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8I exact cutover plan smoke"
