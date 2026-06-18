#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gk-ct202-private-loopback-runtime-smoke-temporary-only"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gj-ct202-private-controller-import-and-db-path-preflight-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gj-smoke.out
echo "PASS: previous Phase 14J-GJ smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GK_CT202_PRIVATE_LOOPBACK_RUNTIME_SMOKE_TEMPORARY_ONLY"
require_fixed "PHASE_14J_GK_RESULT=ct202_private_loopback_runtime_smoke_passed_temporary_only"
require_fixed "APPROVE_PHASE_14J_GK_CT202_PRIVATE_LOOPBACK_RUNTIME_SMOKE_TEMPORARY_ONLY"
require_fixed "PHASE_14J_GK_CT_ID=202"
require_fixed "PHASE_14J_GK_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GK_STATUS=running"
require_fixed "PHASE_14J_GK_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "first GK attempt successfully reached /openapi.json"
require_fixed "GK-R1A attempted broad cleanup and exited with 143"
require_fixed "GK-R1B used exact argv matching"
require_fixed "temporary Uvicorn bind was 127.0.0.1 only"
require_fixed "temporary Uvicorn port was 17070"
require_fixed "/openapi.json returned HTTP 200"
require_fixed "required OpenAPI paths were present"
require_fixed "CT202 DB hash was unchanged before and after the runtime smoke"
require_fixed "SQLite quick_check passed after the runtime smoke"
require_fixed "temporary Uvicorn process was stopped"
require_fixed "exact matching temporary Uvicorn processes were absent after cleanup"
require_fixed "loopback port listener was absent after stop"
require_fixed "edge-queue-controller systemd service was not created"
require_fixed "edge-queue-controller runtime was not active after the smoke"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no persistent controller runtime activation"
require_fixed "no persistent Uvicorn process left running"
require_fixed "no systemd service creation"
require_fixed "no systemd start"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no data import"
require_fixed "no live laptop DB mutation"
require_fixed "no CT202 DB mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gl_ct202_private_auth_flow_runtime_smoke_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
