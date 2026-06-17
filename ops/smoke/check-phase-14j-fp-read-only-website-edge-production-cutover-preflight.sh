#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-fp-read-only-website-edge-production-cutover-preflight"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- required positive markers ---"
require_fixed "PHASE_14J_FP_READ_ONLY_WEBSITE_EDGE_PRODUCTION_CUTOVER_PREFLIGHT"
require_fixed "PHASE_14J_FP_RESULT=read_only_preflight_passed_no_apply"
require_fixed "preflight_passed_no_apply"
require_fixed "website-edge-test.alexhartel.com"
require_fixed "alexhartel.com"
require_fixed "www.alexhartel.com did not resolve during FP-R4 fingerprinting"
require_fixed "Ubuntu 26.04 LTS"
require_fixed "nginx -t config test was successful"
require_fixed "token env file owner/mode verified as root:root 600"
require_fixed "cloudflared-update.service absent"
require_fixed "cloudflared-update.timer absent"
require_fixed "Docker absent"
require_fixed "Node absent"
require_fixed "npm absent"

echo "--- asset hash markers ---"
require_fixed "1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b"
require_fixed "c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19"
require_fixed "5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b"

echo "--- required no-apply markers ---"
require_fixed "no Cloudflare production route mutation"
require_fixed "Gate C is not satisfied"
require_fixed "Gate D rollback readiness still requires explicit rollback"
require_fixed "A future production apply phase requires a new explicit approval"

echo "--- hard-denial markers ---"
require_fixed "no controller/queue migration"
require_fixed "no worker start"
require_fixed "no production DB/job mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "--- secret/raw endpoint guard on doc ---"
if grep -Eq 'eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
