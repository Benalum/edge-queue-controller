#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BX smoke: static UI copy/layout readiness contract ==="

DOC="docs/phase-14j-bx-static-ui-copy-layout-readiness-contract.md"

test -f "$DOC"

for marker in \
  "PHASE_14J_BX_STATIC_UI_COPY_LAYOUT_READINESS_CONTRACT" \
  "MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts" \
  "STATIC_UI_PATCH_READINESS=ready_for_bounded_controller_owned_static_patch_batch" \
  "ALLOWED_PATCH_TYPE=copy_text_polish" \
  "ALLOWED_PATCH_TYPE=layout_class_polish" \
  "ALLOWED_PATCH_TYPE=static_contract_marker" \
  "ALLOWED_PATCH_TYPE=non_runtime_ui_copy" \
  "BLOCKED_PATCH_TYPE=runtime_activation" \
  "BLOCKED_PATCH_TYPE=service_restart_reload" \
  "BLOCKED_PATCH_TYPE=ct101_model_ollama_call" \
  "BLOCKED_PATCH_TYPE=db_or_job_mutation" \
  "BLOCKED_PATCH_TYPE=scheduler_worker_lane_activation" \
  "BLOCKED_PATCH_TYPE=router_or_warmup_activation" \
  "REQUIRED_VALIDATION=ultra_concise_static_baseline" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: readiness marker found: $marker"
done

echo "PASS: static UI copy/layout readiness contract smoke passed"
