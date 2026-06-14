#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-s-admin-auth-bound-disabled-warmup-endpoint"
fail=0

echo "=== ${PHASE}: static admin auth boundary checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-n-static-admin-warmup-endpoint-contract-smoke.sh || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

def segment(node):
    return ast.get_source_segment(src, node) or ""

def is_admin_warmup_route(deco):
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
for node in tree.body:
    if isinstance(node, ast.AsyncFunctionDef):
        if any(is_admin_warmup_route(deco) for deco in node.decorator_list):
            route = node
            break

assert route is not None, "missing POST /admin/model-warmup route"
assert route.name == "admin_model_warmup", "unexpected route function name"

arg_names = [arg.arg for arg in route.args.args]
assert "request" in arg_names, "route missing request parameter"
assert "payload" in arg_names, "route missing payload parameter"

route_src = segment(route)

assert "_admin_support_require_admin(request)" in route_src, "admin guard missing"
assert route_src.index("_admin_support_require_admin(request)") < route_src.index("_stage5p12m_disabled_admin_model_warmup_response"), "admin guard must run before warmup refusal response"
assert "raise HTTPException(status_code=403, detail=response)" in route_src, "disabled refusal missing"

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

print("PASS: admin auth boundary is static-verified before disabled warmup refusal")
PY

echo
echo "=== safety: no live endpoint call performed ==="
echo "PASS: static checks only; no restart and no POST call"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
