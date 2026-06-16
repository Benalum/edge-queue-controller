#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BT smoke: controller-owned static UI and route contract batch ==="

DOC="docs/phase-14j-bt-controller-owned-static-ui-and-route-contract-batch.md"
ROUTE_DOC="docs/phase-14j-bt-controller-owned-route-and-ui-ownership-map.md"
SMOKE="ops/smoke/check-phase-14j-bt-controller-owned-static-ui-and-route-contract-batch.sh"
ROUTE_MAP_SMOKE="ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh"
SAFE_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-baseline.sh"

test -f "$DOC"
test -f "$ROUTE_DOC"
test -f "$SMOKE"
test -x "$ROUTE_MAP_SMOKE"
test -x "$SAFE_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_BT_CONTROLLER_OWNED_STATIC_UI_AND_ROUTE_CONTRACT_BATCH" \
  "MUTATION_SCOPE=docs_smoke_only_static_contracts" \
  "BT_ARTIFACTS_ADDED=three" \
  "SAFE_STATIC_BASELINE_SMOKE=created" \
  "SAFE_UI_PATCH_RULE=controller_owned_static_only" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "SAFE_BATCH_MODE=enabled" \
  "PARALLELIZE_SAFE_GREEN_WORK" \
  "SERIALIZE_RUNTIME_CHANGES" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "LANE_WORKER_ENABLEMENT=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed" \
  "WARMUP_EXECUTION_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
  "NEXT_SAFE_PHASE=phase_14j_bu_controller_owned_static_ui_patch_batch_or_milestone_consolidation"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BT marker found: $marker"
done

bash "$ROUTE_MAP_SMOKE"

echo "PASS: Phase 14J-BT controller-owned static UI and route contract smoke passed"
