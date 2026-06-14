#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-n-static-admin-warmup-endpoint-contract-smoke"
fail=0

echo "=== ${PHASE}: static contract checks ==="

python3 -m py_compile edge_controller.py || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

path = Path("edge_controller.py")
src = path.read_text()
tree = ast.parse(src)

def segment(node):
    return ast.get_source_segment(src, node) or ""

def is_app_post_admin_model_warmup(deco):
    if not isinstance(deco, ast.Call):
        return False
    fn = deco.func
    if not (
        isinstance(fn, ast.Attribute)
        and fn.attr == "post"
        and isinstance(fn.value, ast.Name)
        and fn.value.id == "app"
    ):
        return False
    return bool(deco.args and isinstance(deco.args[0], ast.Constant) and deco.args[0].value == "/admin/model-warmup")

route = None
helper = None
status_helper = None

for node in tree.body:
    if isinstance(node, ast.AsyncFunctionDef):
        if any(is_app_post_admin_model_warmup(d) for d in node.decorator_list):
            route = node
    if isinstance(node, ast.FunctionDef):
        if node.name == "_stage5p12m_disabled_admin_model_warmup_response":
            helper = node
        if node.name == "_stage5p12r_model_memory_status_read_only":
            status_helper = node

assert route is not None, "missing POST /admin/model-warmup route"
assert route.name == "admin_model_warmup", "unexpected route function name"
assert helper is not None, "missing Phase 12R-M helper"
assert status_helper is not None, "missing model memory status helper"

route_src = segment(route)
helper_src = segment(helper)
status_src = segment(status_helper)

assert "_stage5p12m_disabled_admin_model_warmup_response" in route_src
assert "raise HTTPException" in route_src
assert "status_code=403" in route_src
assert "detail=response" in route_src

for forbidden in [
    "/api/generate",
    "/api/chat",
    "ollama.generate",
    "ollama.chat",
    "subprocess",
    "systemctl",
    "ai-platform-laptop-queue-worker",
    "EDGE_ROUTER_ROLLOUT",
]:
    assert forbidden not in route_src, f"forbidden runtime marker in route: {forbidden}"

assert 'status["admin_model_warmup_endpoint"]' in status_src

for required in [
    "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "disabled_endpoint_skeleton",
    "/admin/model-warmup",
    "POST",
    "dry_run_only",
    "runtime_action_available",
    "admin_endpoint_available",
    "would_call",
    "none",
    "EDGE_MODEL_WARMUP_ACTION_ENABLED=1",
    "warmup_action_disabled",
]:
    assert required in helper_src, f"helper missing required marker: {required}"

print("PASS: static endpoint contract is intact")
PY

echo
echo "=== safety: no live endpoint call performed ==="
echo "PASS: smoke used AST/static checks only"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
