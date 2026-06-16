#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BS smoke: batched static smoke coverage and safe UI contract candidates ==="

DOC="docs/phase-14j-bs-batched-static-smoke-coverage-and-safe-ui-contract-candidates.md"
SMOKE="ops/smoke/check-phase-14j-bs-batched-static-smoke-coverage-and-safe-ui-contract-candidates.sh"
ROUTE_SMOKE="ops/smoke/check-phase-14j-bs-public-route-ownership-static-contract.sh"
UI_SMOKE="ops/smoke/check-phase-14j-bs-product-ui-static-contract.sh"
PARKED_SMOKE="ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh"
CANDIDATE_SMOKE="ops/smoke/check-phase-14j-bs-safe-patch-candidate-index.sh"

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -x "$ROUTE_SMOKE"
test -x "$UI_SMOKE"
test -x "$PARKED_SMOKE"
test -x "$CANDIDATE_SMOKE"
echo "PASS: required BS doc and reusable smokes exist"

echo
echo "=== doc markers ==="
for marker in \
  "PHASE_14J_BS_BATCHED_STATIC_SMOKE_COVERAGE_AND_SAFE_UI_CONTRACT_CANDIDATES" \
  "MUTATION_SCOPE=docs_smoke_only_static_contracts" \
  "BS_REUSABLE_SMOKES_ADDED=four" \
  "SAFE_PATCH_CANDIDATE_INDEX=created" \
  "CANDIDATE_CLASS=public_route_ownership_static_contracts" \
  "CANDIDATE_CLASS=product_ui_static_contracts" \
  "CANDIDATE_CLASS=parked_runtime_no_touch_contracts" \
  "CANDIDATE_CLASS=controller_owned_safe_ui_polish" \
  "CANDIDATE_CLASS=next_milestone_consolidation" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
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
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
  "NEXT_SAFE_PHASE=phase_14j_bt_controller_owned_static_ui_and_route_contract_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: doc marker found: $marker"
done

echo
echo "=== run reusable BS smokes ==="
"$ROUTE_SMOKE"
"$UI_SMOKE"
"$PARKED_SMOKE"
"$CANDIDATE_SMOKE"

echo
echo "PASS: Phase 14J-BS batched static smoke coverage smoke passed"
