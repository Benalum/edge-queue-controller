#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CA smoke: static UI patch verification and milestone decision ==="

DOC="docs/phase-14j-ca-static-ui-patch-verification-and-milestone-decision.md"
MILESTONE_DOC="docs/phase-14j-ca-safe-batching-milestone-decision.md"
SMOKE="ops/smoke/check-phase-14j-ca-static-ui-patch-verification-and-milestone-decision.sh"
POST_VERIFY_SMOKE="ops/smoke/check-phase-14j-ca-bz-static-ui-patch-post-verify.sh"
MILESTONE_SMOKE="ops/smoke/check-phase-14j-ca-safe-batching-milestone-decision.sh"

test -f "$DOC"
test -f "$MILESTONE_DOC"
test -f "$SMOKE"
test -x "$POST_VERIFY_SMOKE"
test -x "$MILESTONE_SMOKE"

for marker in \
  "PHASE_14J_CA_STATIC_UI_PATCH_VERIFICATION_AND_MILESTONE_DECISION" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_verification" \
  "BZ_STATIC_UI_PATCH_POST_VERIFY=passed" \
  "MILESTONE_STATUS=first_bounded_static_ui_patch_completed" \
  "SOURCE_REFRESH_DECISION=defer_continue_same_chat" \
  "NEXT_BATCHING_DECISION=continue_safe_static_batches" \
  "CA_ARTIFACTS_ADDED=four" \
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
  "NEXT_SAFE_PHASE=phase_14j_cb_second_bounded_static_ui_or_route_contract_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: CA marker found: $marker"
done

bash "$POST_VERIFY_SMOKE"
bash "$MILESTONE_SMOKE"

echo "PASS: Phase 14J-CA static UI patch verification smoke passed"
