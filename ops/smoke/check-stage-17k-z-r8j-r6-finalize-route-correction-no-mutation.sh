#!/usr/bin/env bash
set -euo pipefail

RAW_OUT="docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.txt"
JSON_OUT="docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.json"
DOC="docs/stage-17k-z-r8j-r6-finalize-route-correction-no-mutation.md"

echo "=== Stage 17K-Z-R8J-R6 final correction smoke ==="

test -f "$RAW_OUT"
test -f "$JSON_OUT"
test -f "$DOC"

grep -Fq "product_domain=buddieswhostudy.com" "$RAW_OUT"
grep -Fq "www_domain=www.buddieswhostudy.com" "$RAW_OUT"
grep -Fq "current_domain=alexhartel.com" "$RAW_OUT"
grep -Fq "register_http=403" "$RAW_OUT"
grep -Fq "closed_beta_signup_disabled" "$RAW_OUT"
grep -Fq "register_http=000" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8J-R6"' "$JSON_OUT"
grep -Fq '"product_domain_dns_has_host_answer": false' "$JSON_OUT"
grep -Fq '"www_domain_dns_has_host_answer": false' "$JSON_OUT"
grep -Fq '"product_domain_http_resolves": false' "$JSON_OUT"
grep -Fq '"www_domain_http_resolves": false' "$JSON_OUT"
grep -Fq '"product_domain_closed_beta_frontend_public": false' "$JSON_OUT"
grep -Fq '"www_domain_closed_beta_frontend_public": false' "$JSON_OUT"
grep -Fq '"product_domain_register_403": false' "$JSON_OUT"
grep -Fq '"www_domain_register_403": false' "$JSON_OUT"
grep -Fq '"authority_status": "product_domain_nameservers_set_but_no_public_host_records"' "$JSON_OUT"
grep -Fq '"go_for_dns_mutation_now": "manual_dashboard_only_after_user_approval"' "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8J-R6" "$DOC"
grep -Fq "not yet publicly routed" "$DOC"
grep -Fq "manual Cloudflare/dashboard route addition" "$DOC"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8J-R6 final correction smoke"
