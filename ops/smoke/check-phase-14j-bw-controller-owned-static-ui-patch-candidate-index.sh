#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BW smoke: controller-owned static UI patch candidate index ==="

DOC="docs/phase-14j-bw-controller-owned-static-ui-patch-candidate-index.md"
ACTIVE_SOURCE_SMOKE="ops/smoke/check-phase-14j-bw-active-source-only-ui-route-inventory.sh"

test -f "$DOC"
test -x "$ACTIVE_SOURCE_SMOKE"

for marker in \
  "PHASE_14J_BW_CONTROLLER_OWNED_STATIC_UI_PATCH_CANDIDATE_INDEX" \
  "MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts" \
  "ACTIVE_SOURCE_ONLY_INVENTORY=created" \
  "DOCS_NOISE_EXCLUDED=enabled" \
  "STATIC_UI_PATCH_CANDIDATES=identified" \
  "CANDIDATE_CLASS=controller_owned_public_pages" \
  "CANDIDATE_CLASS=controller_owned_account_profile_credits_system" \
  "CANDIDATE_CLASS=controller_owned_wrapper_static_assets" \
  "CANDIDATE_CLASS=cloudflare_public_gateway_static_contracts" \
  "CANDIDATE_CLASS=protected_ct101_app_surfaces_read_only_only" \
  "SAFE_UI_PATCH_RULE=controller_owned_static_only" \
  "PROTECTED_RUNTIME_SURFACES=read_only_until_explicit_approval" \
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
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: candidate marker found: $marker"
done

bash "$ACTIVE_SOURCE_SMOKE"

echo "PASS: controller-owned static UI patch candidate index smoke passed"
