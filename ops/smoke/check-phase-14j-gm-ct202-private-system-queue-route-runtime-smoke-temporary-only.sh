#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gm-ct202-private-system-queue-route-runtime-smoke-temporary-only"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gl-ct202-private-auth-flow-runtime-smoke-temporary-only.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gl-smoke.out
echo "PASS: previous Phase 14J-GL smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GM_CT202_PRIVATE_SYSTEM_QUEUE_ROUTE_RUNTIME_SMOKE_TEMPORARY_ONLY"
require_fixed "PHASE_14J_GM_RESULT=ct202_private_system_queue_route_runtime_smoke_passed_temporary_only"
require_fixed "APPROVE_PHASE_14J_GM_CT202_PRIVATE_SYSTEM_QUEUE_ROUTE_RUNTIME_SMOKE_TEMPORARY_ONLY"
require_fixed "PHASE_14J_GM_CT_ID=202"
require_fixed "PHASE_14J_GM_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GM_STATUS=running"
require_fixed "PHASE_14J_GM_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "temporary in-process CT202-only public API key"
require_fixed "was not printed"
require_fixed "was not committed"
require_fixed "was not stored in Source"
require_fixed "was not made persistent"
require_fixed "temporary Uvicorn bind was 127.0.0.1 only"
require_fixed "temporary Uvicorn port was 17072"
require_fixed "/openapi.json returned HTTP 200"
require_fixed "OpenAPI path count was 147"
require_fixed "OpenAPI system/status/health route count was 55"
require_fixed "OpenAPI queue/job/worker route count was 27"
require_fixed "safe GET probe candidate count was 16"
require_fixed "safe GET probe count was 16"
require_fixed "safe GET system/status/health probe count was 12"
require_fixed "safe GET queue/job/worker probe count was 4"
require_fixed "safe GET 5xx skipped count was 0"
require_fixed "no POST/PUT/PATCH/DELETE route probes were performed"
require_fixed "no job creation was performed"
require_fixed "no queue mutation was performed"
require_fixed "CT202 DB hash stayed unchanged on the settled DB"
require_fixed "CT202 table count stayed 25"
require_fixed "SQLite quick_check passed after the route smoke"
require_fixed "temporary Uvicorn process was stopped"
require_fixed "exact matching temporary Uvicorn process was absent after cleanup"
require_fixed "loopback port listener was absent after stop"
require_fixed "edge-queue-controller systemd service was not created"
require_fixed "edge-queue-controller runtime was not active after the smoke"
require_fixed "GM-R1A smoke found the route inventory and GET probes worked"
require_fixed "DB file hash changed after GET probes"
require_fixed "all inspected tables had zero rows"
require_fixed "GM-R1B reran the same route smoke on the settled 25-table DB"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no route smoke rerun in record phase"
require_fixed "no persistent controller runtime activation"
require_fixed "no persistent Uvicorn process left running"
require_fixed "no systemd service creation"
require_fixed "no systemd start"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no data import"
require_fixed "no live laptop DB mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "no token or password recording"
require_fixed "no public API key recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gn_ct202_default_off_controller_systemd_unit_draft_no_enable_no_start_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
