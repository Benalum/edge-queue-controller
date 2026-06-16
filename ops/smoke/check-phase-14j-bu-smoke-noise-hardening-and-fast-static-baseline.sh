#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BU smoke: smoke-noise hardening and fast static baseline ==="

DOC="docs/phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.md"
SMOKE="ops/smoke/check-phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.sh"
NOISE_SMOKE="ops/smoke/check-phase-14j-bu-no-cleanup-archive-static-inventory-output.sh"
FAST_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-fast-baseline.sh"

test -f "$DOC"
test -f "$SMOKE"
test -x "$NOISE_SMOKE"
test -x "$FAST_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_BU_SMOKE_NOISE_HARDENING_AND_FAST_STATIC_BASELINE" \
  "MUTATION_SCOPE=smoke_docs_only_static_workflow_hardening" \
  "STATIC_INVENTORY_NOISE=cleanup_archive_paths_removed" \
  "BU_ARTIFACTS_ADDED=three" \
  "PATCHED_STATIC_SMOKE_EXCLUDES=cleanup_archive_and_backups" \
  "SAFE_STATIC_FAST_BASELINE_SMOKE=created" \
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
  "NEXT_SAFE_PHASE=phase_14j_bv_controller_owned_static_ui_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: BU marker found: $marker"
done

bash "$NOISE_SMOKE"
bash "$FAST_BASELINE_SMOKE"

echo "PASS: Phase 14J-BU smoke-noise hardening and fast static baseline smoke passed"
