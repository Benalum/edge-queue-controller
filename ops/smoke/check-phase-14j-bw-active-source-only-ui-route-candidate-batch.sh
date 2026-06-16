#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BW smoke: active source-only UI route candidate batch ==="

DOC="docs/phase-14j-bw-active-source-only-ui-route-candidate-batch.md"
CANDIDATE_DOC="docs/phase-14j-bw-controller-owned-static-ui-patch-candidate-index.md"
SMOKE="ops/smoke/check-phase-14j-bw-active-source-only-ui-route-candidate-batch.sh"
ACTIVE_SOURCE_SMOKE="ops/smoke/check-phase-14j-bw-active-source-only-ui-route-inventory.sh"
CANDIDATE_SMOKE="ops/smoke/check-phase-14j-bw-controller-owned-static-ui-patch-candidate-index.sh"
ULTRA_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-ultra-concise-baseline.sh"

test -f "$DOC"
test -f "$CANDIDATE_DOC"
test -f "$SMOKE"
test -x "$ACTIVE_SOURCE_SMOKE"
test -x "$CANDIDATE_SMOKE"
test -x "$ULTRA_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_BW_ACTIVE_SOURCE_ONLY_UI_ROUTE_CANDIDATE_BATCH" \
  "MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts" \
  "BW_ARTIFACTS_ADDED=four" \
  "ACTIVE_SOURCE_ONLY_INVENTORY=created" \
  "STATIC_UI_PATCH_CANDIDATES=identified" \
  "SAFE_STATIC_ULTRA_CONCISE_BASELINE_SMOKE=created" \
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
  "NEXT_SAFE_PHASE=phase_14j_bx_controller_owned_static_ui_copy_layout_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BW marker found: $marker"
done

bash "$ACTIVE_SOURCE_SMOKE"
bash "$CANDIDATE_SMOKE"
bash "$ULTRA_BASELINE_SMOKE"

echo "PASS: Phase 14J-BW active source-only UI route candidate batch smoke passed"
