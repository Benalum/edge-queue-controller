#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8h-readonly-buddieswhostudy-domain-cutover-readiness.md"
OUT="docs/generated/stage-17k-z-r8h-readonly-buddieswhostudy-domain-cutover-readiness.txt"
JSON_OUT="docs/generated/stage-17k-z-r8h-readonly-buddieswhostudy-domain-cutover-readiness.json"

echo "=== Stage 17K-Z-R8H-R2 readiness finalize smoke ==="

test -f "$DOC"
test -f "$OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8H" "$DOC"
grep -Fq "read-only inventory completed and finalized" "$DOC"
grep -Fq "buddieswhostudy.com" "$DOC"
grep -Fq "alexhartel.com" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$DOC"
grep -Fq "VM200 SSH timeout" "$DOC"
grep -Fq "PVEW SSH timeout" "$DOC"
grep -Fq "product_domain=buddieswhostudy.com" "$OUT"
grep -Fq "register_http=403" "$OUT"
grep -Fq "closed_beta_signup_disabled" "$OUT"
grep -Fq '"stage": "17K-Z-R8H"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"closed_beta_backend_gate_live_on_current_domain": true' "$JSON_OUT"
grep -Fq '"closed_beta_frontend_marker_live_on_current_domain": true' "$JSON_OUT"
grep -Fq '"needs_dns_cloudflare_cutover": true' "$JSON_OUT"
grep -Fq '"recommended_next_stage": "R8I prepare exact Cloudflare/DNS change plan, still no mutation unless approved"' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8H-R2 readiness finalize smoke"
