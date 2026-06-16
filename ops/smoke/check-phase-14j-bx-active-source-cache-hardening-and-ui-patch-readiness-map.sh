#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BX smoke: active source cache hardening and UI patch readiness map ==="

DOC="docs/phase-14j-bx-active-source-cache-hardening-and-ui-patch-readiness-map.md"
MAP_DOC="docs/phase-14j-bx-controller-owned-active-source-ui-map.md"
READINESS_DOC="docs/phase-14j-bx-static-ui-copy-layout-readiness-contract.md"
SMOKE="ops/smoke/check-phase-14j-bx-active-source-cache-hardening-and-ui-patch-readiness-map.sh"
ACTIVE_MAP_SMOKE="ops/smoke/check-phase-14j-bx-active-source-ui-map-inventory.sh"
MAP_SMOKE="ops/smoke/check-phase-14j-bx-controller-owned-active-source-ui-map.sh"
READINESS_SMOKE="ops/smoke/check-phase-14j-bx-static-ui-copy-layout-readiness-contract.sh"
NO_CACHE_SMOKE="ops/smoke/check-phase-14j-bx-no-cache-active-source-inventory-output.sh"
ULTRA_V2_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-ultra-concise-v2-baseline.sh"

test -f "$DOC"
test -f "$MAP_DOC"
test -f "$READINESS_DOC"
test -f "$SMOKE"
test -x "$ACTIVE_MAP_SMOKE"
test -x "$MAP_SMOKE"
test -x "$READINESS_SMOKE"
test -x "$NO_CACHE_SMOKE"
test -x "$ULTRA_V2_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_BX_ACTIVE_SOURCE_CACHE_HARDENING_AND_UI_PATCH_READINESS_MAP" \
  "MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts" \
  "BX_REPAIR_RESULT=recursive_smoke_fixed" \
  "BX_ARTIFACTS_ADDED=six" \
  "ACTIVE_SOURCE_CACHE_EXCLUDED=enabled" \
  "STATIC_UI_PATCH_READINESS=ready_for_bounded_controller_owned_static_patch_batch" \
  "SAFE_STATIC_ULTRA_CONCISE_V2_BASELINE_SMOKE=created" \
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
  "NEXT_SAFE_PHASE=phase_14j_by_controller_owned_static_ui_copy_layout_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BX marker found: $marker"
done

bash "$ACTIVE_MAP_SMOKE"
bash "$MAP_SMOKE"
bash "$READINESS_SMOKE"
bash "$NO_CACHE_SMOKE"
bash "$ULTRA_V2_BASELINE_SMOKE"

echo "PASS: Phase 14J-BX active source cache hardening smoke passed"
