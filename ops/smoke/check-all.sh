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
echo "=== rewarded ad status behavior ==="
ops/smoke/check-rewarded-ad-status-behavior.sh

echo
echo "=== rewarded ad claim behavior ==="
ops/smoke/check-rewarded-ad-claim-behavior.sh

echo
echo "=== credit pool lifecycle behavior ==="
ops/smoke/check-credit-pool-lifecycle.sh

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
echo "=== credit ownership ==="
ops/smoke/check-credit-ownership.sh

echo
echo "PASS: all controller smoke checks passed"
