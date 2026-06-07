#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ -x "$ROOT/.venv/bin/python3" ]; then
  export PATH="$ROOT/.venv/bin:$PATH"
fi

echo "=== python environment ==="
python3 - <<'PYENV'
import sys
print(sys.executable)
import fastapi
print("fastapi import ok")
PYENV

echo
echo "=== compile controller modules ==="
python3 -m py_compile \
  edge_controller.py \
  edge_modules/credit_helpers.py \
  edge_modules/rewarded_ads.py

echo
echo "=== extracted helper behavior ==="
ops/smoke/check-extracted-helper-behavior.sh

echo
echo "=== email verification auth behavior ==="
ops/smoke/check-email-verification-auth.sh

echo
echo "=== auth token expiration config ==="
ops/smoke/check-auth-token-expiration-config.sh

echo
echo "=== email verification API aliases ==="
ops/smoke/check-email-verification-api-aliases.sh

echo
echo "=== change password auth behavior ==="
ops/smoke/check-change-password-auth.sh

echo
echo "=== password reset auth behavior ==="
ops/smoke/check-password-reset-auth.sh

echo
echo "=== public gateway email verification routes ==="
ops/smoke/check-public-gateway-email-verification-routes.sh

echo
echo "=== rewarded ad status behavior ==="
ops/smoke/check-rewarded-ad-status-behavior.sh

echo
echo "=== rewarded ad claim behavior ==="
ops/smoke/check-rewarded-ad-claim-behavior.sh

echo
echo "=== credit pool lifecycle behavior ==="
ops/smoke/check-credit-pool-lifecycle.sh

echo
echo "=== companion pending UX ==="
ops/smoke/check-companion-pending-ux.sh

echo
echo "=== companion helper definitions ==="
ops/smoke/check-companion-helper-duplicates.sh

echo
echo "=== duplicate route registrations ==="
ops/smoke/check-duplicate-routes.sh

echo
echo "=== public gateway duplicate route registrations ==="
ops/smoke/check-public-gateway-duplicate-routes.sh

echo
echo "=== public gateway rewarded-ad route gating ==="
ops/smoke/check-public-gateway-ad-reward-routes.sh

echo
echo "=== rewarded-ad deployment config ==="
ops/smoke/check-rewarded-ad-deploy-config.sh

echo
echo "=== credit ownership ==="
ops/smoke/check-credit-ownership.sh

echo
echo "=== wrapper auth/proxy contract ==="
ops/smoke/check-wrapper-auth-proxy-contract.sh

echo
echo "=== route ownership contract ==="
ops/smoke/check-route-ownership-contract.sh

echo
echo "=== public route map consistency ==="
ops/smoke/check-public-route-map-consistency.sh

echo
echo "=== public system status routes ==="
ops/smoke/check-public-system-status-routes.sh

echo
echo "=== system status normalized contract docs ==="
ops/smoke/check-system-status-normalized-contract.sh

echo
echo "=== system status normalized runtime shape ==="
ops/smoke/check-system-status-normalized-runtime.sh

echo
echo "=== system status UI normalized fallback ==="
ops/smoke/check-system-status-ui-normalized-fallback.sh

echo
echo "PASS: all controller smoke checks passed"
