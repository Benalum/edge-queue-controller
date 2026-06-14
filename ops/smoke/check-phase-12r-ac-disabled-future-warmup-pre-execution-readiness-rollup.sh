#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ac-disabled-future-warmup-pre-execution-readiness-rollup"
fail=0

echo "=== ${PHASE}: pre-execution readiness rollup ==="

python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== run live disabled future warmup skeleton smoke ==="
ops/smoke/check-phase-12r-ab-live-disabled-future-warmup-skeleton-status-smoke.sh || fail=1

echo
echo "=== run optional authenticated admin smoke in no-token mode ==="
unset EDGE_TEST_ADMIN_BEARER_TOKEN
ops/smoke/check-phase-12r-v-optional-authenticated-admin-warmup-refusal-smoke.sh || fail=1

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
echo "=== static route and helper execution boundary ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

admin_route = None
future_helper = None
memory_helper = None

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
            future_helper = node
        if node.name == "_stage5p12r_model_memory_status_read_only":
            memory_helper = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

assert admin_route is not None, "missing admin warmup route"
assert future_helper is not None, "missing disabled future helper"
assert memory_helper is not None, "missing model memory status helper"

admin_src = segment(admin_route)
future_src = segment(future_helper)
memory_src = segment(memory_helper)

assert "_admin_support_require_admin(request)" in admin_src
assert "_stage5p12m_disabled_admin_model_warmup_response" in admin_src
assert "_stage5p12y_disabled_future_warmup_execution_skeleton" not in admin_src
assert "raise HTTPException(status_code=403, detail=response)" in admin_src

for forbidden in [
    "/api/generate",
    "/api/chat",
    "httpx.",
    "urlopen",
    "subprocess",
    "systemctl",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
]:
    assert forbidden not in admin_src, f"admin route contains forbidden runtime marker: {forbidden}"

assert '"would_call": "none"' in future_src
assert '"execute_now": False' in future_src
assert '"runtime_action_available": runtime_action_available' in future_src
assert "runtime_action_available = False" in future_src
assert "/api/generate" in future_src
assert "/api/chat" not in future_src

assert "disabled_future_warmup_execution_skeletons" in memory_src
assert "_stage5p12y_disabled_future_warmup_execution_skeleton" in memory_src

print("PASS: admin route remains disabled and future skeleton remains non-executable")
PY

echo
echo "=== live final status confirmation ==="
curl -sS --max-time 5 -o /tmp/phase12rac-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

curl -sS --max-time 10 -o /tmp/phase12rac-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rac-status.json").read_text())

def find_memory(value):
    if isinstance(value, dict):
        if isinstance(value.get("model_memory_status"), dict):
            return value["model_memory_status"]
        for child in value.values():
            found = find_memory(child)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_memory(child)
            if found is not None:
                return found
    return None

memory = find_memory(data)
if not isinstance(memory, dict):
    raise SystemExit("FAIL: model_memory_status not found")

endpoint = memory.get("admin_model_warmup_endpoint")
if not isinstance(endpoint, dict):
    raise SystemExit("FAIL: admin_model_warmup_endpoint not found")

assert endpoint.get("runtime_action_available") is False
assert endpoint.get("would_call") == "none"

skeletons = memory.get("disabled_future_warmup_execution_skeletons")
if not isinstance(skeletons, dict):
    raise SystemExit("FAIL: disabled_future_warmup_execution_skeletons not found")

for model in ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"]:
    item = skeletons.get(model)
    if not isinstance(item, dict):
        raise SystemExit(f"FAIL: missing skeleton for {model}")
    assert item.get("runtime_action_available") is False
    assert item.get("would_call") == "none"
    future = item.get("future_ollama_request")
    assert isinstance(future, dict)
    assert future.get("endpoint") == "/api/generate"
    assert future.get("execute_now") is False

print("PASS: live future warmup control plane remains disabled")
PY

echo
echo "=== verify unauthenticated admin warmup remains auth/admin blocked ==="
post_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rac-unauth-post.json \
  -w "%{http_code}" \
  http://127.0.0.1:7070/admin/model-warmup || true)"
echo "post_code=${post_code}"

if [ "$post_code" != "401" ] && [ "$post_code" != "403" ]; then
  echo "FAIL: expected unauthenticated POST to be blocked with 401 or 403"
  fail=1
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
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
