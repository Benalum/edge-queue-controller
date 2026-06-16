#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J safe static ultra-concise baseline smoke ==="
echo "MUTATION_SCOPE=read_only_static_ultra_concise_baseline"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO service restart/reload"
echo "NO scheduler activation"
echo "NO worker activation"
echo "NO runtime activation"

smokes=(
  "ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh"
  "ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh"
  "ops/smoke/check-phase-14j-bw-active-source-only-ui-route-inventory.sh"
  "ops/smoke/check-phase-14j-bw-controller-owned-static-ui-patch-candidate-index.sh"
)

for smoke in "${smokes[@]}"; do
  echo
  echo "=== ultra baseline: $smoke ==="
  test -x "$smoke"
  bash "$smoke"
done

echo
echo "PASS: Phase 14J safe static ultra-concise baseline smoke passed"
