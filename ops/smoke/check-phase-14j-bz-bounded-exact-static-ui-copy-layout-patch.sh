#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BZ smoke: bounded exact static UI copy/layout patch ==="

DOC="docs/phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.md"
MANIFEST="docs/phase-14j-bz-static-ui-copy-layout-patch-manifest.md"

test -f "$DOC"
test -f "$MANIFEST"

echo
echo "=== manifest markers ==="
for marker in \
  "PHASE_14J_BZ_STATIC_UI_COPY_LAYOUT_PATCH_MANIFEST" \
  "MUTATION_SCOPE=active_source_static_ui_copy_layout_only" \
  "STATIC_UI_PATCH_APPLIED=bounded_exact_static_copy_layout" \
  "PATCH_TYPE=title_meta_polish" \
  "PATCH_TYPE=static_phase_marker" \
  "PATCH_TYPE=static_body_data_marker" \
  "PATCH_TYPE=non_runtime_ui_comment_marker" \
  "PATCH_BOUNDARY=tracked_active_static_ui_source_only" \
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
echo "=== static source markers ==="
patched_count=0
for file in index.html frontend/study-ui/index.html app.js frontend/study-ui/app.js; do
  if git ls-files --error-unmatch "$file" >/dev/null 2>&1 && [ -f "$file" ]; then
    if grep -F "APC_PHASE_14J_BZ_STATIC_UI_PATCH" "$file" >/dev/null; then
      echo "PASS: BZ static UI marker found in $file"
      patched_count=$((patched_count + 1))
    else
      echo "CHECK: BZ static UI marker not present in $file"
    fi
  fi
done

if [ "$patched_count" -le 0 ]; then
  echo "FAIL: no BZ static UI markers found in tracked candidate files"
  exit 1
fi

echo
echo "=== syntax checks ==="
python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  for file in app.js frontend/study-ui/app.js cloudflare/edge-public-proxy/src/index.js; do
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1 && [ -f "$file" ]; then
      echo "node_check=$file"
      node --check "$file"
    fi
  done
else
  echo "CHECK: node not available; skipped JS syntax check"
fi

echo
echo "PASS: Phase 14J-BZ bounded exact static UI copy/layout patch smoke passed"
