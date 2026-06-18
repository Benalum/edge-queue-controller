#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gi-r0-ct202-auth-schema-bootstrap-gap-inspection-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gh-ct202-fresh-sqlite-db-created-default-off-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gh-smoke.out
echo "PASS: previous Phase 14J-GH smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GI_R0_CT202_AUTH_SCHEMA_BOOTSTRAP_GAP_INSPECTION_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GI_R0_RESULT=ct202_auth_schema_bootstrap_gap_inspected_no_runtime_activation"
require_fixed "PHASE_14J_GI_R0_CT_ID=202"
require_fixed "PHASE_14J_GI_R0_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GI_R0_STATUS=running"
require_fixed "PHASE_14J_GI_R0_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "PHASE_14J_GI_R0_SCHEMA_GAP_TARGET=auth_user_session_credit_tables"
require_fixed "app_users"
require_fixed "user_sessions"
require_fixed "pending_email_signups"
require_fixed "password_reset_tokens"
require_fixed "user_credit_wallets"
require_fixed "credit_ledger"
require_fixed "credit_reservations"
require_fixed "PHASE_14J_GI_R0_RECOMMENDED_NEXT=add_or_run_default_off_auth_schema_bootstrap_artifact"
require_fixed "APPROVE_PHASE_14J_GI_APPLY_CT202_AUTH_SCHEMA_BOOTSTRAP_DEFAULT_OFF"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no CT202 DB mutation"
require_fixed "no auth schema apply"
require_fixed "no controller runtime activation"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_gi_apply_ct202_auth_schema_bootstrap_default_off_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
