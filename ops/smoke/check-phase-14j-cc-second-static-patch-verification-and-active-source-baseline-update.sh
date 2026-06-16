#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CC smoke: second static patch verification and active-source baseline update ==="

DOC="docs/phase-14j-cc-second-static-patch-verification-and-active-source-baseline-update.md"
BASELINE_DOC="docs/phase-14j-cc-active-source-static-baseline-v3-update.md"
SMOKE="ops/smoke/check-phase-14j-cc-second-static-patch-verification-and-active-source-baseline-update.sh"
CB_POST_VERIFY_SMOKE="ops/smoke/check-phase-14j-cc-cb-static-ui-route-patch-post-verify.sh"
BASELINE_V3_SMOKE="ops/smoke/check-phase-14j-safe-static-ultra-concise-v3-baseline.sh"

test -f "$DOC"
test -f "$BASELINE_DOC"
test -f "$SMOKE"
test -x "$CB_POST_VERIFY_SMOKE"
test -x "$BASELINE_V3_SMOKE"

for marker in \
  "PHASE_14J_CC_SECOND_STATIC_PATCH_VERIFICATION_AND_ACTIVE_SOURCE_BASELINE_UPDATE" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_verification_and_baseline_update" \
  "CB_STATIC_UI_ROUTE_PATCH_POST_VERIFY=passed" \
  "ACTIVE_SOURCE_STATIC_BASELINE_VERSION=v3_created" \
  "SAFE_STATIC_ULTRA_CONCISE_V3_BASELINE_SMOKE=created" \
  "CC_ARTIFACTS_ADDED=four" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "SOURCE_REFRESH_DECISION=defer_continue_same_chat" \
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
  "NEXT_SAFE_PHASE=phase_14j_cd_third_static_ui_or_gateway_contract_patch_batch"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: CC marker found: $marker"
done

for marker in \
  "PHASE_14J_CC_ACTIVE_SOURCE_STATIC_BASELINE_V3_UPDATE" \
  "ACTIVE_SOURCE_STATIC_BASELINE_VERSION=v3_created" \
  "CB_STATIC_UI_ROUTE_PATCH_POST_VERIFY=passed" \
  "SAFE_STATIC_ULTRA_CONCISE_V3_BASELINE_SMOKE=created" \
  "V3_BASELINE_INCLUDES=parked_runtime_default_off_guard" \
  "V3_BASELINE_INCLUDES=no_cache_active_source_inventory_guard" \
  "V3_BASELINE_INCLUDES=ca_static_ui_milestone_verification" \
  "V3_BASELINE_INCLUDES=bz_static_ui_patch_smoke" \
  "V3_BASELINE_INCLUDES=cb_static_ui_route_contract_smoke" \
  "V3_BASELINE_INCLUDES=cc_cb_post_verify_smoke"
do
  grep -F "$marker" "$BASELINE_DOC" >/dev/null
  echo "PASS: baseline marker found: $marker"
done

bash "$CB_POST_VERIFY_SMOKE"
bash "$BASELINE_V3_SMOKE"

echo "PASS: Phase 14J-CC second static patch verification smoke passed"
