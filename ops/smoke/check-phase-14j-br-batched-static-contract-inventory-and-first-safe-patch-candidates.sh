#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BR smoke: batched static contract inventory and first safe patch candidates ==="

DOC="docs/phase-14j-br-batched-static-contract-inventory-and-first-safe-patch-candidates.md"
SMOKE="ops/smoke/check-phase-14j-br-batched-static-contract-inventory-and-first-safe-patch-candidates.sh"
PUBLIC_SMOKE="ops/smoke/check-phase-14j-br-public-product-surface-static-inventory.sh"
RUNTIME_SMOKE="ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh"
CADENCE_SMOKE="ops/smoke/check-phase-14j-br-source-cadence-and-ppb-contract.sh"

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -x "$PUBLIC_SMOKE"
test -x "$RUNTIME_SMOKE"
test -x "$CADENCE_SMOKE"
echo "PASS: required BR doc and reusable smokes exist"

echo
echo "=== doc markers ==="
for marker in \
  "PHASE_14J_BR_BATCHED_STATIC_CONTRACT_INVENTORY_AND_FIRST_SAFE_PATCH_CANDIDATES" \
  "MUTATION_SCOPE=docs_smoke_only_static_contracts" \
  "PPB_HARD_BLOCK_LITERAL_AVOIDANCE=enabled" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "BR_REUSABLE_SMOKES_ADDED=three" \
  "SAFE_BATCH_MODE=enabled" \
  "PARALLELIZE_SAFE_GREEN_WORK" \
  "SERIALIZE_RUNTIME_CHANGES" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "CT101_MODEL_JOB_MUTATION=not_performed" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "LANE_WORKER_ENABLEMENT=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed" \
  "WARMUP_EXECUTION_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER" \
  "FIRST_SAFE_PATCH_CANDIDATES=identified" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
  "NEXT_SAFE_PHASE=phase_14j_bs_batched_static_smoke_coverage_and_safe_ui_contract_candidates"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: doc marker found: $marker"
done

echo
echo "=== run reusable BR smokes ==="
"$PUBLIC_SMOKE"
"$RUNTIME_SMOKE"
"$CADENCE_SMOKE"

echo
echo "PASS: Phase 14J-BR batched static contract inventory smoke passed"
