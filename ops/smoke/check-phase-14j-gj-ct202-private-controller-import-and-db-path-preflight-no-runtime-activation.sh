#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gj-ct202-private-controller-import-and-db-path-preflight-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gi-ct202-auth-schema-bootstrap-repaired-default-off-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gi-smoke.out
echo "PASS: previous Phase 14J-GI smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GJ_CT202_PRIVATE_CONTROLLER_IMPORT_AND_DB_PATH_PREFLIGHT_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GJ_RESULT=ct202_private_controller_import_and_db_path_preflight_passed_no_runtime_activation"
require_fixed "PHASE_14J_GJ_CT_ID=202"
require_fixed "PHASE_14J_GJ_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GJ_STATUS=running"
require_fixed "PHASE_14J_GJ_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "edge_controller imported successfully under the CT202 venv"
require_fixed "edge_controller.app was present"
require_fixed "edge_controller.DB_PATH resolved to /srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "SQLite quick_check passed"
require_fixed "required auth/session/credit/jobs tables were present"
require_fixed "CT202 DB hash was unchanged before and after import preflight"
require_fixed "edge-queue-controller systemd service was not created"
require_fixed "edge-queue-controller runtime was not active"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no CT202 DB mutation"
require_fixed "no controller runtime activation"
require_fixed "no uvicorn start"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_gk_ct202_private_loopback_runtime_smoke_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
