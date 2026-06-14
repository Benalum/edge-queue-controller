#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-y-disabled-future-warmup-execution-helper-skeleton"
fail=0

echo "=== ${PHASE}: static disabled helper skeleton checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-x-inspect-only-warmup-execution-boundary-design.sh || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper = None
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
        if node.name == "_stage5p12y_disabled_future_warmup_execution_skeleton":
            helper = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

assert helper is not None, "missing Phase 12R-Y helper"
assert admin_route is not None, "missing admin warmup route"

helper_src = segment(helper)
admin_src = segment(admin_route)

required = [
    "phase_12r_y_disabled_future_warmup_execution_skeleton",
    "disabled_future_execution_skeleton",
    "runtime_action_available",
    '"would_call": "none"',
    "/api/generate",
    '"execute_now": False',
    "runtime_action_unavailable",
    "EDGE_MODEL_WARMUP_ACTION_ENABLED",
    "_stage5p12k_manual_warmup_dry_run",
]
for item in required:
    assert item in helper_src, f"helper missing marker: {item}"

for forbidden in [
    "httpx.",
    "urlopen",
    "urllib",
    "subprocess",
    "/api/chat",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "systemctl",
]:
    assert forbidden not in helper_src, f"helper contains forbidden runtime marker: {forbidden}"

assert "_stage5p12y_disabled_future_warmup_execution_skeleton" not in admin_src, "admin route must not call future helper yet"
assert "_stage5p12m_disabled_admin_model_warmup_response" in admin_src, "admin route must keep disabled response helper"

print("PASS: Phase 12R-Y helper is disabled and not wired into runtime route")
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
