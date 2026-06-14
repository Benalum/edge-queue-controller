#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-z-disabled-future-warmup-skeleton-status-attachment"
fail=0

echo "=== ${PHASE}: static status attachment checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-y-disabled-future-warmup-execution-helper-skeleton.sh || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

memory_helper = None
future_helper = None
admin_route = None

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

for node in tree.body:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        if node.name == "_stage5p12r_model_memory_status_read_only":
            memory_helper = node
        if node.name == "_stage5p12y_disabled_future_warmup_execution_skeleton":
            future_helper = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

assert memory_helper is not None, "missing model memory helper"
assert future_helper is not None, "missing Phase 12R-Y future helper"
assert admin_route is not None, "missing admin warmup route"

memory_src = segment(memory_helper)
future_src = segment(future_helper)
admin_src = segment(admin_route)

assert "disabled_future_warmup_execution_skeletons" in memory_src
for model in ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"]:
    assert model in memory_src, f"missing status skeleton model: {model}"

assert "_stage5p12y_disabled_future_warmup_execution_skeleton" in memory_src
assert '"future_ollama_request"' in future_src
assert '"/api/generate"' in future_src
assert '"execute_now": False' in future_src
assert '"would_call": "none"' in future_src

assert "_stage5p12y_disabled_future_warmup_execution_skeleton" not in admin_src
assert "_stage5p12m_disabled_admin_model_warmup_response" in admin_src

for forbidden in [
    "httpx.",
    "urlopen(",
    "subprocess.run(",
    "/api/chat",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "systemctl",
]:
    assert forbidden not in future_src, f"future helper contains forbidden runtime marker: {forbidden}"

print("PASS: disabled future warmup skeletons are attached to read-only status only")
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
