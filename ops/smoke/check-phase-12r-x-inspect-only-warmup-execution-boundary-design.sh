#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-x-inspect-only-warmup-execution-boundary-design"
fail=0

echo "=== ${PHASE}: static execution boundary checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-w-disabled-warmup-control-plane-readiness-rollup.sh || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

def segment(node):
    return ast.get_source_segment(src, node) or ""

def route_path(deco):
    if not isinstance(deco, ast.Call):
        return None
    fn = deco.func
    if not (
        isinstance(fn, ast.Attribute)
        and isinstance(fn.value, ast.Name)
        and fn.value.id == "app"
    ):
        return None
    if deco.args and isinstance(deco.args[0], ast.Constant):
        return f"{fn.attr.upper()} {deco.args[0].value}"
    return None

admin_route = None
direct_ollama_route = None
memory_helper = None
blueprint_helper = None
disabled_helper = None

for node in tree.body:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        for deco in node.decorator_list:
            route = route_path(deco)
            if route == "POST /admin/model-warmup":
                admin_route = node
            if route == "POST /tick/ollama-direct":
                direct_ollama_route = node

        if node.name == "_stage5p12r_model_memory_status_read_only":
            memory_helper = node
        if node.name == "_stage5p12l_disabled_manual_warmup_action_blueprint":
            blueprint_helper = node
        if node.name == "_stage5p12m_disabled_admin_model_warmup_response":
            disabled_helper = node

assert admin_route is not None, "missing admin model warmup route"
assert direct_ollama_route is not None, "missing existing direct Ollama route"
assert memory_helper is not None, "missing model memory helper"
assert blueprint_helper is not None, "missing disabled manual warmup blueprint"
assert disabled_helper is not None, "missing disabled admin warmup response helper"

admin_src = segment(admin_route)
memory_src = segment(memory_helper)
blueprint_src = segment(blueprint_helper)
disabled_src = segment(disabled_helper)
direct_src = segment(direct_ollama_route)

assert "_admin_support_require_admin(request)" in admin_src
assert "_stage5p12m_disabled_admin_model_warmup_response" in admin_src
assert "raise HTTPException(status_code=403, detail=response)" in admin_src

for forbidden in [
    "/api/generate",
    "/api/chat",
    "httpx.",
    "urllib",
    "urlopen",
    "subprocess",
    "systemctl",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
]:
    assert forbidden not in admin_src, f"admin warmup route contains forbidden runtime marker: {forbidden}"

for allowed_read in ["/api/version", "/api/tags", "/api/ps"]:
    assert allowed_read in memory_src, f"memory helper missing expected read marker: {allowed_read}"

for forbidden in ["/api/generate", "/api/chat"]:
    assert forbidden not in memory_src, f"memory helper contains forbidden execution endpoint: {forbidden}"

assert "/api/generate" in blueprint_src
assert "execute_now" in blueprint_src
assert "False" in blueprint_src
assert '"would_call": "none"' in blueprint_src
assert '"runtime_action_available": runtime_action_available' in blueprint_src

assert '"runtime_action_available": False' in disabled_src
assert '"would_call": "none"' in disabled_src
assert '"reason": "warmup_action_disabled"' in disabled_src

assert "EDGE_DIRECT_OLLAMA_FORWARD" in direct_src
assert "DIRECT_OLLAMA_FORWARD" in direct_src
assert "/api/chat" not in admin_src

print("PASS: warmup execution boundary remains inspect-only and disabled")
PY

echo
echo "=== safety summary ==="
echo "PASS: no edge_controller.py patch was required"
echo "PASS: no controller restart was performed"
echo "PASS: no Ollama direct execution call was made by this smoke"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat warmup call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
