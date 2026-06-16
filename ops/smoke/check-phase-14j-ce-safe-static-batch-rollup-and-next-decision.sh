#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CE smoke: safe static batch rollup and next decision ==="

DOC="docs/phase-14j-ce-safe-static-batch-rollup-and-next-decision.md"

test -f "$DOC"

for marker in \
  "PHASE_14J_CE_SAFE_STATIC_BATCH_ROLLUP_AND_NEXT_DECISION" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_verification_and_rollup" \
  "SAFE_STATIC_PATCH_BATCH_COUNT=three_completed" \
  "COMPLETED_STATIC_PATCH=batch_bz_static_ui_copy_layout" \
  "COMPLETED_STATIC_PATCH=batch_cb_static_ui_route_contract" \
  "COMPLETED_STATIC_PATCH=batch_cd_static_ui_gateway_contract" \
  "CD_STATIC_UI_GATEWAY_PATCH_POST_VERIFY=passed" \
  "ACTIVE_SOURCE_STATIC_BASELINE_VERSION=v4_created" \
  "SAFE_STATIC_ULTRA_CONCISE_V4_BASELINE_SMOKE=created" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "SOURCE_REFRESH_DECISION=eligible_for_handoff_refresh_but_deferred_until_user_requests" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "NEXT_BATCHING_DECISION=pause_for_user_direction_or_continue_safe_static_batches" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
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
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: rollup marker found: $marker"
done

echo "PASS: safe static batch rollup smoke passed"
