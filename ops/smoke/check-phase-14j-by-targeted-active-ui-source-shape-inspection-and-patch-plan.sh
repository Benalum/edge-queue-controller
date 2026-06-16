#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BY smoke: targeted active UI source-shape inspection and patch plan ==="

DOC="docs/phase-14j-by-targeted-active-ui-source-shape-inspection-and-patch-plan.md"
PATCH_PLAN_DOC="docs/phase-14j-by-controller-owned-static-ui-copy-layout-patch-plan.md"
SMOKE="ops/smoke/check-phase-14j-by-targeted-active-ui-source-shape-inspection-and-patch-plan.sh"
PATCH_PLAN_SMOKE="ops/smoke/check-phase-14j-by-controller-owned-static-ui-copy-layout-patch-plan.sh"

test -f "$DOC"
test -f "$PATCH_PLAN_DOC"
test -f "$SMOKE"
test -x "$PATCH_PLAN_SMOKE"

for marker in \
  "PHASE_14J_BY_TARGETED_ACTIVE_UI_SOURCE_SHAPE_INSPECTION_AND_PATCH_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_targeted_source_shape" \
  "TARGETED_ACTIVE_UI_SOURCE_SHAPE=completed" \
  "STATIC_UI_PATCH_TARGET_RECOMMENDATIONS=derived" \
  "PATCH_BATCH_DECISION=plan_only_until_exact_targets_confirmed" \
  "NEXT_PATCH_MODE=bounded_exact_string_patch" \
  "BY_ARTIFACTS_ADDED=three" \
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
  "NEXT_SAFE_PHASE=phase_14j_bz_bounded_exact_static_ui_copy_layout_patch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BY marker found: $marker"
done

bash "$PATCH_PLAN_SMOKE"

echo "PASS: Phase 14J-BY targeted active UI source-shape inspection smoke passed"
