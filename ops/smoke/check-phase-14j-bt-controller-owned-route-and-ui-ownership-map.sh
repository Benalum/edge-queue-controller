#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BT smoke: controller-owned route and UI ownership map ==="

DOC="docs/phase-14j-bt-controller-owned-route-and-ui-ownership-map.md"

test -f "$DOC"

for marker in \
  "PHASE_14J_BT_CONTROLLER_OWNED_ROUTE_AND_UI_OWNERSHIP_MAP" \
  "MUTATION_SCOPE=docs_smoke_only_static_contracts" \
  "CONTROLLER_OWNED_SURFACES=static_public_controller_routes" \
  "PROXY_OR_APP_SURFACES=protected_runtime_or_ct101_boundaries" \
  "SAFE_UI_PATCH_RULE=controller_owned_static_only" \
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
  echo "PASS: route/UI ownership marker found: $marker"
done

echo "PASS: controller-owned route and UI ownership map smoke passed"
