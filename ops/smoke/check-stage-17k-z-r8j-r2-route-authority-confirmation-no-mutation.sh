#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.md"
RAW_OUT="docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.txt"
JSON_OUT="docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.json"

echo "=== Stage 17K-Z-R8J-R2 route authority smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8J-R2" "$DOC"
grep -Fq "Route Authority Confirmation" "$DOC"
grep -Fq "buddieswhostudy.com" "$DOC"
grep -Fq "provider API-token usage" "$DOC"
grep -Fq "Do not mutate DNS or routing" "$DOC"

grep -Fq "product_domain=buddieswhostudy.com" "$RAW_OUT"
grep -Fq "current_domain=alexhartel.com" "$RAW_OUT"
grep -Fq "provider_api_inventory=skipped_no_token_usage" "$RAW_OUT"
grep -Fq "## public DNS comparison" "$RAW_OUT"
grep -Fq "## public HTTP/headers comparison" "$RAW_OUT"
grep -Fq "## registration gate comparison" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8J-R2"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"provider_api_inventory": "skipped_no_token_usage"' "$JSON_OUT"
grep -Fq '"product_domain": "buddieswhostudy.com"' "$JSON_OUT"
grep -Fq '"current_domain": "alexhartel.com"' "$JSON_OUT"
grep -Fq '"authority_status":' "$JSON_OUT"
grep -Fq '"recommended_next_stage":' "$JSON_OUT"
grep -Fq '"go_for_dns_mutation_now": false' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8J-R2 route authority smoke"
