#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gg-ct202-python-venv-dependency-install-default-off-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gf-clone-controller-code-default-off-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gf-smoke.out
echo "PASS: previous Phase 14J-GF smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GG_CT202_PYTHON_VENV_DEPENDENCY_INSTALL_DEFAULT_OFF_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GG_RESULT=ct202_python_venv_dependencies_installed_default_off_no_runtime_activation"
require_fixed "PHASE_14J_GG_CT_ID=202"
require_fixed "PHASE_14J_GG_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GG_STATUS=running"
require_fixed "PHASE_14J_GG_VENV_PATH=/srv/edge-controller/venv"
require_fixed "PHASE_14J_GG_DEPENDENCY_INSTALL_MODE=requirements.txt"
require_fixed "Python venv exists"
require_fixed "pip check passed"
require_fixed "edge_controller.py py_compile passed"
require_fixed "FastAPI import passed"
require_fixed "Uvicorn import passed"
require_fixed "edge-queue-controller systemd service was not created"
require_fixed "edge-queue-controller runtime was not active"
require_fixed "FORBIDDEN_ABSENT=docker"
require_fixed "FORBIDDEN_ABSENT=node"
require_fixed "FORBIDDEN_ABSENT=npm"
require_fixed "FORBIDDEN_ABSENT=nginx"
require_fixed "FORBIDDEN_ABSENT=cloudflared"
require_fixed "FORBIDDEN_ABSENT=ollama"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no dependency install rerun in record phase"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_gh_ct202_fresh_sqlite_bootstrap_plan_no_runtime_activation"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
