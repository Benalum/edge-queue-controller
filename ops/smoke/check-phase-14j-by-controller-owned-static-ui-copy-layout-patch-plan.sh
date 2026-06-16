#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BY smoke: controller-owned static UI copy/layout patch plan ==="

DOC="docs/phase-14j-by-controller-owned-static-ui-copy-layout-patch-plan.md"

test -f "$DOC"

for marker in \
  "PHASE_14J_BY_CONTROLLER_OWNED_STATIC_UI_COPY_LAYOUT_PATCH_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_targeted_source_shape" \
  "TARGETED_ACTIVE_UI_SOURCE_SHAPE=completed" \
  "STATIC_UI_PATCH_TARGET_RECOMMENDATIONS=derived" \
  "PATCH_BATCH_DECISION=plan_only_until_exact_targets_confirmed" \
  "NEXT_PATCH_MODE=bounded_exact_string_patch" \
  "ALLOWED_PATCH_MODE=exact_string_static_copy_layout_patch" \
  "ALLOWED_PATCH_TYPE=copy_text_polish" \
  "ALLOWED_PATCH_TYPE=title_meta_polish" \
  "ALLOWED_PATCH_TYPE=static_accessibility_label" \
  "ALLOWED_PATCH_TYPE=static_layout_class_polish" \
  "ALLOWED_PATCH_TYPE=non_runtime_ui_comment_marker" \
  "BLOCKED_PATCH_TYPE=runtime_activation" \
  "BLOCKED_PATCH_TYPE=service_restart_reload" \
  "BLOCKED_PATCH_TYPE=ct101_model_ollama_call" \
  "BLOCKED_PATCH_TYPE=db_or_job_mutation" \
  "BLOCKED_PATCH_TYPE=scheduler_worker_lane_activation" \
  "BLOCKED_PATCH_TYPE=router_or_warmup_activation" \
  "REQUIRED_VALIDATION=ultra_concise_v2_static_baseline" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: patch plan marker found: $marker"
done

echo "PASS: controller-owned static UI copy/layout patch plan smoke passed"
