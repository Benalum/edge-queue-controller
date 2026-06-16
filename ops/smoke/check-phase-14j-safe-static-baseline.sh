#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J safe static baseline smoke ==="
echo "MUTATION_SCOPE=read_only_static_baseline"
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
  "ops/smoke/check-phase-14j-bn-docs-smoke-only-activation-planning-decision-record.sh"
  "ops/smoke/check-phase-14j-bo-read-only-runtime-rollback-evidence-plan.sh"
  "ops/smoke/check-phase-14j-bp-read-only-activation-go-no-go-readiness-review.sh"
  "ops/smoke/check-phase-14j-bq-parallel-safe-workstream-plan-and-static-surface-inventory.sh"
  "ops/smoke/check-phase-14j-br-batched-static-contract-inventory-and-first-safe-patch-candidates.sh"
  "ops/smoke/check-phase-14j-br-public-product-surface-static-inventory.sh"
  "ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh"
  "ops/smoke/check-phase-14j-br-source-cadence-and-ppb-contract.sh"
  "ops/smoke/check-phase-14j-bs-batched-static-smoke-coverage-and-safe-ui-contract-candidates.sh"
  "ops/smoke/check-phase-14j-bs-public-route-ownership-static-contract.sh"
  "ops/smoke/check-phase-14j-bs-product-ui-static-contract.sh"
  "ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh"
  "ops/smoke/check-phase-14j-bs-safe-patch-candidate-index.sh"
  "ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh"
)

for smoke in "${smokes[@]}"; do
  echo
  echo "=== run $smoke ==="
  test -x "$smoke"
  bash "$smoke"
done

echo
echo "PASS: Phase 14J safe static baseline smoke passed"
