#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BV smoke: active static inventory hardening and concise baseline ==="

DOC="docs/phase-14j-bv-active-static-inventory-hardening-and-concise-baseline.md"
SMOKE="ops/smoke/check-phase-14j-bv-active-static-inventory-hardening-and-concise-baseline.sh"
ACTIVE_SMOKE="ops/smoke/check-phase-14j-bv-active-public-product-surface-static-inventory.sh"
NOISE_SMOKE="ops/smoke/check-phase-14j-bv-no-historical-static-inventory-output.sh"
CONCISE_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-concise-baseline.sh"

test -f "$DOC"
test -f "$SMOKE"
test -x "$ACTIVE_SMOKE"
test -x "$NOISE_SMOKE"
test -x "$CONCISE_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_BV_ACTIVE_STATIC_INVENTORY_HARDENING_AND_CONCISE_BASELINE" \
  "MUTATION_SCOPE=smoke_docs_only_static_workflow_hardening" \
  "STATIC_INVENTORY_NOISE=historical_cleanup_and_bridge_paths_removed" \
  "BV_ARTIFACTS_ADDED=four" \
  "PATCHED_STATIC_SMOKE_EXCLUDES=historical_noise_dirs" \
  "SAFE_STATIC_CONCISE_BASELINE_SMOKE=created" \
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
  "NEXT_SAFE_PHASE=phase_14j_bw_controller_owned_static_ui_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BV marker found: $marker"
done

bash "$ACTIVE_SMOKE"
bash "$NOISE_SMOKE"
bash "$CONCISE_BASELINE_SMOKE"

echo "PASS: Phase 14J-BV active static inventory hardening smoke passed"
