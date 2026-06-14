#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ae-admin-disabled-warmup-refusal-future-preview"
fail=0

echo "=== ${PHASE}: static disabled admin future preview checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-ac-disabled-future-warmup-pre-execution-readiness-rollup.sh || fail=1

python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper = None
future_helper = None
memory_helper = None
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
        if node.name == "_stage5p12m_disabled_admin_model_warmup_response":
            helper = node
        if node.name == "_stage5p12y_disabled_future_warmup_execution_skeleton":
            future_helper = node
        if node.name == "_stage5p12r_model_memory_status_read_only":
            memory_helper = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

assert helper is not None, "missing disabled admin helper"
assert future_helper is not None, "missing future skeleton helper"
assert memory_helper is not None, "missing model memory status helper"
assert admin_route is not None, "missing admin warmup route"

helper_src = segment(helper)
future_src = segment(future_helper)
admin_src = segment(admin_route)

assert "status: dict | None = None" in helper_src
assert "future_warmup_execution_preview" in helper_src
assert "_stage5p12y_disabled_future_warmup_execution_skeleton(model, status)" in helper_src
assert '"runtime_action_available": False' in helper_src
assert '"would_call": "none"' in helper_src

assert "_admin_support_require_admin(request)" in admin_src
assert "_stage5p12r_model_memory_status_read_only()" in admin_src
assert "_stage5p12m_disabled_admin_model_warmup_response(model, dry_run=dry_run, status=status)" in admin_src
assert "raise HTTPException(status_code=403, detail=response)" in admin_src

assert '"future_ollama_request"' in future_src
assert '"/api/generate"' in future_src
assert '"execute_now": False' in future_src
assert '"would_call": "none"' in future_src
assert "runtime_action_available = False" in future_src

for forbidden in [
    "/api/chat",
    "httpx.",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "systemctl",
]:
    assert forbidden not in helper_src, f"helper contains forbidden marker: {forbidden}"
    assert forbidden not in future_src, f"future helper contains forbidden marker: {forbidden}"

# The admin route may call the read-only memory helper, but must not directly call execution endpoints.
for forbidden in [
    "/api/generate",
    "/api/chat",
    "httpx.",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "systemctl",
]:
    assert forbidden not in admin_src, f"admin route contains forbidden execution marker: {forbidden}"

print("PASS: admin disabled refusal includes non-executable future preview only")
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no Ollama generate/chat call was added"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
