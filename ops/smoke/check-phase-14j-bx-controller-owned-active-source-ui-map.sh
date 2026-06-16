#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BX smoke: active source UI map doc ==="

DOC="docs/phase-14j-bx-controller-owned-active-source-ui-map.md"
ACTIVE_MAP_SMOKE="ops/smoke/check-phase-14j-bx-active-source-ui-map-inventory.sh"

test -f "$DOC"
test -x "$ACTIVE_MAP_SMOKE"

for marker in \
  "PHASE_14J_BX_CONTROLLER_OWNED_ACTIVE_SOURCE_UI_MAP" \
  "MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts" \
  "ACTIVE_SOURCE_UI_MAP=completed" \
  "ACTIVE_SOURCE_CACHE_EXCLUDED=enabled" \
  "CANDIDATE_CLASS=controller_public_ui" \
  "CANDIDATE_CLASS=cloudflare_gateway_static_contracts" \
  "CANDIDATE_CLASS=study_ui_static_read_only_candidate" \
  "CANDIDATE_CLASS=companion_ui_static_read_only_candidate" \
  "CANDIDATE_CLASS=calendar_static_read_only_candidate" \
  "CANDIDATE_CLASS=protected_runtime_read_only_only" \
  "SAFE_UI_PATCH_RULE=controller_owned_static_only" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: map marker found: $marker"
done

bash "$ACTIVE_MAP_SMOKE"

echo "PASS: active source UI map doc smoke passed"
