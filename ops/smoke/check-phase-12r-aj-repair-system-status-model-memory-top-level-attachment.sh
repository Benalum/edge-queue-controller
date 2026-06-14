#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-aj-repair-system-status-model-memory-top-level-attachment"
fail=0

echo "=== ${PHASE}: static repair checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static verify lightweight top-level /system/status attachment ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

uncached = None
helper = None

for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_system_status_uncached":
        uncached = node
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p12aj_public_model_memory_status_snapshot":
        helper = node

if uncached is None:
    raise SystemExit("FAIL: _system_status_uncached not found")
if helper is None:
    raise SystemExit("FAIL: lightweight snapshot helper not found")

returns = [node for node in ast.walk(uncached) if isinstance(node, ast.Return)]
if len(returns) != 1:
    raise SystemExit(f"FAIL: expected one return in _system_status_uncached, found {len(returns)}")

return_src = ast.get_source_segment(src, returns[0]) or ""
helper_src = ast.get_source_segment(src, helper) or ""

required_return = [
    '"model_memory_status": _stage5p12aj_public_model_memory_status_snapshot()',
    '"normalized": _system_status_normalized_block(nodes, services)',
    '"services": services',
    '"nodes": nodes',
]
for marker in required_return:
    if marker not in return_src:
        raise SystemExit(f"FAIL: return block missing marker: {marker}")

if "_stage5p12r_model_memory_status_read_only()" in return_src:
    raise SystemExit("FAIL: /system/status still calls full read-only model memory scan")

required_helper = [
    '"network_calls": False',
    '"runtime_action_available": False',
    '"would_call": "none"',
    '"admin_model_warmup_endpoint"',
    '"disabled_future_warmup_execution_skeletons"',
    '_stage5p12m_disabled_admin_model_warmup_response(',
    '_stage5p12y_disabled_future_warmup_execution_skeleton(model, status={})',
]
for marker in required_helper:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing marker: {marker}")

for label, text in [
    ("return_block", return_src),
    ("helper", helper_src),
]:
    for forbidden in [
        "httpx.",
        "urlopen",
        "urllib.request",
        "requests.",
        "subprocess",
        "systemctl",
        "_forward_ollama_chat_job_direct",
        "tick_ollama_direct",
    ]:
        if forbidden in text:
            raise SystemExit(f"FAIL: {label} contains forbidden marker: {forbidden}")

print("PASS: _system_status_uncached uses lightweight top-level model_memory_status snapshot")
PY

echo
echo "=== static verify disabled warmup route remains disabled ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

admin_route = None

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
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

if admin_route is None:
    raise SystemExit("FAIL: admin warmup route not found")

admin_src = ast.get_source_segment(src, admin_route) or ""
if "_admin_support_require_admin(request)" not in admin_src:
    raise SystemExit("FAIL: admin route missing admin guard")
if "raise HTTPException(status_code=403, detail=response)" not in admin_src:
    raise SystemExit("FAIL: admin route no longer raises disabled 403")

for forbidden in [
    "/api/generate",
    "/api/chat",
    "httpx.",
    "urlopen",
    "urllib.request",
    "requests.",
    "subprocess",
    "systemctl",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
]:
    if forbidden in admin_src:
        raise SystemExit(f"FAIL: admin route contains forbidden marker: {forbidden}")

print("PASS: admin warmup route remains disabled")
PY

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed by this smoke"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
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
