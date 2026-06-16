#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J safe static concise baseline smoke ==="
echo "MUTATION_SCOPE=read_only_static_concise_baseline"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO service restart/reload"
echo "NO scheduler activation"
echo "NO worker activation"
echo "NO runtime activation"

smokes=(
  "ops/smoke/check-phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint.sh"
  "ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh"
  "ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh"
  "ops/smoke/check-phase-14j-bv-active-public-product-surface-static-inventory.sh"
  "ops/smoke/check-phase-14j-bv-no-historical-static-inventory-output.sh"
)

for smoke in "${smokes[@]}"; do
  echo
  echo "=== concise baseline: $smoke ==="
  test -x "$smoke"
  bash "$smoke"
done

echo
echo "PASS: Phase 14J safe static concise baseline smoke passed"
