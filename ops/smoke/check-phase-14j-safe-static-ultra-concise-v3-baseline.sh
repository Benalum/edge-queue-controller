#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J safe static ultra-concise v3 baseline smoke ==="
echo "MUTATION_SCOPE=read_only_static_ultra_concise_v3_baseline"
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
  "ops/smoke/check-phase-14j-bx-no-cache-active-source-inventory-output.sh"
  "ops/smoke/check-phase-14j-ca-static-ui-patch-verification-and-milestone-decision.sh"
  "ops/smoke/check-phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.sh"
  "ops/smoke/check-phase-14j-cb-second-bounded-static-ui-and-route-contract-patch-batch.sh"
  "ops/smoke/check-phase-14j-cc-cb-static-ui-route-patch-post-verify.sh"
)

for smoke in "${smokes[@]}"; do
  echo
  echo "=== ultra v3 baseline: $smoke ==="
  test -x "$smoke"
  bash "$smoke"
done

echo
echo "PASS: Phase 14J safe static ultra-concise v3 baseline smoke passed"
