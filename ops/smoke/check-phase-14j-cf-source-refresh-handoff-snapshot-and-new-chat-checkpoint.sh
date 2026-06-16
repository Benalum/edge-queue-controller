#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CF smoke: source refresh handoff snapshot and new-chat checkpoint ==="

DOC="docs/phase-14j-cf-source-refresh-handoff-snapshot-and-new-chat-checkpoint.md"
PROMPT_DOC="docs/phase-14j-cf-new-chat-continuation-prompt.md"
CE_ROLLUP_SMOKE="ops/smoke/check-phase-14j-ce-safe-static-batch-rollup-and-next-decision.sh"
CE_POST_VERIFY_SMOKE="ops/smoke/check-phase-14j-ce-cd-static-ui-gateway-patch-post-verify.sh"
V4_BASELINE_SMOKE="ops/smoke/check-phase-14j-safe-static-ultra-concise-v4-baseline.sh"

test -f "$DOC"
test -f "$PROMPT_DOC"
test -x "$CE_ROLLUP_SMOKE"
test -x "$CE_POST_VERIFY_SMOKE"
test -x "$V4_BASELINE_SMOKE"

for marker in \
  "PHASE_14J_CF_SOURCE_REFRESH_HANDOFF_SNAPSHOT_AND_NEW_CHAT_CHECKPOINT" \
  "MUTATION_SCOPE=docs_smoke_only_source_refresh_handoff_snapshot" \
  "SOURCE_REFRESH_HANDOFF_SNAPSHOT=created" \
  "NEW_CHAT_CONTINUATION_PROMPT=created" \
  "SAFE_BATCH_MODE=pause_for_handoff" \
  "CURRENT_MILESTONE=three_bounded_static_patch_batches_verified" \
  "COMPLETED_STATIC_PATCH=batch_bz_static_ui_copy_layout" \
  "COMPLETED_STATIC_PATCH=batch_cb_static_ui_route_contract" \
  "COMPLETED_STATIC_PATCH=batch_cd_static_ui_gateway_contract" \
  "ACTIVE_SOURCE_STATIC_BASELINE_VERSION=v4_created" \
  "SAFE_STATIC_ULTRA_CONCISE_V4_BASELINE_SMOKE=available" \
  "SOURCE_REFRESH_RECOMMENDATION=refresh_uploaded_source_files_before_major_next_step" \
  "NEXT_SAFE_OPTION=build_updated_source_files_and_new_chat_handoff" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: CF marker found: $marker"
done

grep -F "PHASE_14J_CF_NEW_CHAT_CONTINUATION_PROMPT" "$PROMPT_DOC" >/dev/null
grep -F "Continue the AI Platform Control project." "$PROMPT_DOC" >/dev/null
grep -F "Runtime activation remains blocked." "$PROMPT_DOC" >/dev/null
echo "PASS: prompt markers found"

bash "$CE_ROLLUP_SMOKE" >/tmp/phase-14j-cf-smoke-ce-rollup.out
echo "PASS: CE rollup smoke passed"

bash "$CE_POST_VERIFY_SMOKE" >/tmp/phase-14j-cf-smoke-ce-post-verify.out
echo "PASS: CE post-verify smoke passed"

echo "PASS: Phase 14J-CF handoff smoke passed"
