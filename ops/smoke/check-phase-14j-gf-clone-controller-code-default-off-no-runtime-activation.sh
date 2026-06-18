#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gf-clone-controller-code-default-off-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-ge-edge-controller-baseline-setup-record.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-ge-smoke.out
echo "PASS: previous Phase 14J-GE smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GF_CLONE_CONTROLLER_CODE_DEFAULT_OFF_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GF_RESULT=controller_code_copied_to_ct202_default_off_no_runtime_activation"
require_fixed "PHASE_14J_GF_CT_ID=202"
require_fixed "PHASE_14J_GF_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GF_RELEASE=controller-da0dc2c"
require_fixed "/srv/edge-controller/app/current"
require_fixed "Python compile check passed"
require_fixed "edge-queue-controller service was not created"
require_fixed "edge-queue-controller runtime was not active"
require_fixed "Docker absent"
require_fixed "Node absent"
require_fixed "npm absent"
require_fixed "nginx absent"
require_fixed "cloudflared absent"
require_fixed "Ollama absent"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no controller runtime activation"
require_fixed "no systemd service creation"
require_fixed "no systemd start"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gg_ct202_python_venv_dependency_install_default_off_no_runtime_activation"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
