#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CB smoke: second bounded static UI and route-contract patch batch ==="

DOC="docs/phase-14j-cb-second-bounded-static-ui-and-route-contract-patch-batch.md"
MANIFEST="docs/phase-14j-cb-static-ui-route-contract-patch-manifest.md"
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
  "PHASE_14J_CB_STATIC_UI_ROUTE_CONTRACT_PATCH_MANIFEST" \
  "MUTATION_SCOPE=active_source_static_ui_route_contract_only" \
  "STATIC_UI_ROUTE_CONTRACT_PATCH_APPLIED=bounded_static_copy_layout_and_contract" \
  "PATCH_TYPE=static_meta_description" \
  "PATCH_TYPE=static_language_attribute" \
  "PATCH_TYPE=static_accessibility_label" \
  "PATCH_TYPE=static_body_data_marker" \
  "PATCH_TYPE=non_runtime_ui_comment_marker" \
  "PATCH_TYPE=non_runtime_route_contract_comment_marker" \
  "PATCH_BOUNDARY=tracked_active_source_static_ui_route_contract_only" \
  "PATCH_TARGET=frontend/study-ui/index.html" \
  "PATCH_TARGET=frontend/study-ui/app.js" \
  "PATCH_TARGET=cloudflare/edge-public-proxy/src/index.js" \
  "REQUIRED_VALIDATION=ultra_concise_v2_static_baseline" \
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
grep -F 'data-apc-static-ui-copy-layout="14j-cb"' "$HTML" >/dev/null

if grep -F '<html' "$HTML" | head -1 | grep -F 'lang=' >/dev/null; then
  echo "PASS: HTML language attribute present"
else
  echo "FAIL: HTML language attribute missing"
  exit 1
fi

if grep -F 'name="description"' "$HTML" >/dev/null; then
  echo "PASS: HTML description meta present"
else
  echo "FAIL: HTML description meta missing"
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
echo "PASS: Phase 14J-CB bounded static UI and route-contract patch smoke passed"
