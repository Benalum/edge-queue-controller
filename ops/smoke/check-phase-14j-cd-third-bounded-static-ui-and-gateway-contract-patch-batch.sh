#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CD smoke: third bounded static UI and gateway contract patch batch ==="

DOC="docs/phase-14j-cd-third-bounded-static-ui-and-gateway-contract-patch-batch.md"
MANIFEST="docs/phase-14j-cd-static-ui-gateway-contract-patch-manifest.md"
HTML="frontend/study-ui/index.html"
APP_JS="frontend/study-ui/app.js"
GATEWAY_JS="cloudflare/edge-public-proxy/src/index.js"

test -f "$DOC"
test -f "$MANIFEST"
test -f "$HTML"
test -f "$APP_JS"
test -f "$GATEWAY_JS"

echo
echo "=== manifest markers ==="
for marker in \
  "PHASE_14J_CD_STATIC_UI_GATEWAY_CONTRACT_PATCH_MANIFEST" \
  "MUTATION_SCOPE=active_source_static_ui_gateway_contract_only" \
  "STATIC_UI_GATEWAY_CONTRACT_PATCH_APPLIED=bounded_static_metadata_and_gateway_contract" \
  "PATCH_TYPE=static_application_metadata" \
  "PATCH_TYPE=static_theme_metadata" \
  "PATCH_TYPE=static_body_gateway_contract_marker" \
  "PATCH_TYPE=non_runtime_ui_contract_comment_marker" \
  "PATCH_TYPE=non_runtime_gateway_route_ownership_comment_marker" \
  "PATCH_BOUNDARY=tracked_active_source_static_ui_gateway_contract_only" \
  "PATCH_TARGET=frontend/study-ui/index.html" \
  "PATCH_TARGET=frontend/study-ui/app.js" \
  "PATCH_TARGET=cloudflare/edge-public-proxy/src/index.js" \
  "REQUIRED_VALIDATION=ultra_concise_v3_static_baseline" \
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
  grep -F "$marker" "$MANIFEST" >/dev/null
  echo "PASS: manifest marker found: $marker"
done

echo
echo "=== source markers ==="
grep -F "APC_PHASE_14J_BZ_STATIC_UI_PATCH" "$HTML" >/dev/null
grep -F "APC_PHASE_14J_BZ_STATIC_UI_PATCH" "$APP_JS" >/dev/null
grep -F "APC_PHASE_14J_CB_STATIC_UI_PATCH" "$APP_JS" >/dev/null
grep -F "APC_PHASE_14J_CB_STATIC_ROUTE_CONTRACT" "$GATEWAY_JS" >/dev/null
grep -F "APC_PHASE_14J_CD_STATIC_UI_CONTRACT" "$APP_JS" >/dev/null
grep -F "APC_PHASE_14J_CD_PUBLIC_GATEWAY_ROUTE_OWNERSHIP_CONTRACT" "$GATEWAY_JS" >/dev/null
grep -F 'data-apc-gateway-contract="14j-cd"' "$HTML" >/dev/null

if grep -F 'name="application-name"' "$HTML" >/dev/null; then
  echo "PASS: HTML application-name metadata present"
else
  echo "FAIL: HTML application-name metadata missing"
  exit 1
fi

if grep -F 'name="theme-color"' "$HTML" >/dev/null; then
  echo "PASS: HTML theme-color metadata present"
else
  echo "FAIL: HTML theme-color metadata missing"
  exit 1
fi

echo
echo "=== syntax checks ==="
python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
  node --check "$GATEWAY_JS"
else
  echo "CHECK: node not available; skipped JS syntax check"
fi

echo
echo "PASS: Phase 14J-CD bounded static UI and gateway contract patch smoke passed"
