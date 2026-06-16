#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CE smoke: third static patch verification and safe batch rollup ==="

DOC="docs/phase-14j-ce-third-static-patch-verification-and-safe-batch-rollup.md"
ROLLUP_DOC="docs/phase-14j-ce-safe-static-batch-rollup-and-next-decision.md"
SMOKE="ops/smoke/check-phase-14j-ce-third-static-patch-verification-and-safe-batch-rollup.sh"
CD_POST_VERIFY_SMOKE="ops/smoke/check-phase-14j-ce-cd-static-ui-gateway-patch-post-verify.sh"
ROLLUP_SMOKE="ops/smoke/check-phase-14j-ce-safe-static-batch-rollup-and-next-decision.sh"
BASELINE_V4_SMOKE="ops/smoke/check-phase-14j-safe-static-ultra-concise-v4-baseline.sh"

test -f "$DOC"
test -f "$ROLLUP_DOC"
test -f "$SMOKE"
test -x "$CD_POST_VERIFY_SMOKE"
test -x "$ROLLUP_SMOKE"
test -x "$BASELINE_V4_SMOKE"

for marker in \
  "PHASE_14J_CE_THIRD_STATIC_PATCH_VERIFICATION_AND_SAFE_BATCH_ROLLUP" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_verification_and_rollup" \
  "CD_STATIC_UI_GATEWAY_PATCH_POST_VERIFY=passed" \
  "SAFE_STATIC_PATCH_BATCH_COUNT=three_completed" \
  "ACTIVE_SOURCE_STATIC_BASELINE_VERSION=v4_created" \
  "SAFE_STATIC_ULTRA_CONCISE_V4_BASELINE_SMOKE=created" \
  "CE_ARTIFACTS_ADDED=five" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "SOURCE_REFRESH_DECISION=eligible_for_handoff_refresh_but_deferred_until_user_requests" \
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
  "NEXT_SAFE_PHASE=phase_14j_cf_user_direction_source_refresh_or_continue_safe_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: CE marker found: $marker"
done

bash "$CD_POST_VERIFY_SMOKE"
bash "$ROLLUP_SMOKE"
bash "$BASELINE_V4_SMOKE"

echo "PASS: Phase 14J-CE third static patch verification smoke passed"
