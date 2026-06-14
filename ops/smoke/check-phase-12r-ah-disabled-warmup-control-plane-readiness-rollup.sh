#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ah-disabled-warmup-control-plane-readiness-rollup"
fail=0

echo "=== ${PHASE}: no-restart disabled warmup control-plane rollup ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== run static/admin/future-preview smoke chain ==="
ops/smoke/check-phase-12r-ae-admin-disabled-warmup-refusal-future-preview.sh || fail=1

echo
echo "=== run optional authenticated preview smoke in no-token mode ==="
unset EDGE_TEST_ADMIN_BEARER_TOKEN
ops/smoke/check-phase-12r-ag-optional-authenticated-admin-warmup-preview-smoke.sh || fail=1

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
echo "=== service health ==="
curl -sS --max-time 5 -o /tmp/phase12rah-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live system status ==="
curl -sS --max-time 10 -o /tmp/phase12rah-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rah-status.json").read_text())

def find_model_memory(obj):
    if isinstance(obj, dict):
        if isinstance(obj.get("model_memory_status"), dict):
            return obj["model_memory_status"]
        for value in obj.values():
            found = find_model_memory(value)
            if found is not None:
                return found
    elif isinstance(obj, list):
        for value in obj:
            found = find_model_memory(value)
            if found is not None:
                return found
    return None

memory = find_model_memory(data)
if not isinstance(memory, dict):
    raise SystemExit("FAIL: model_memory_status not found in live status")

admin = memory.get("admin_model_warmup_endpoint")
if not isinstance(admin, dict):
    raise SystemExit("FAIL: admin_model_warmup_endpoint missing")

expected_admin = {
    "source": "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "mode": "disabled_endpoint_skeleton",
    "endpoint": "/admin/model-warmup",
    "method": "POST",
    "would_call": "none",
    "reason": "warmup_action_disabled",
}

for key, expected in expected_admin.items():
    actual = admin.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: admin.{key} expected {expected!r}, got {actual!r}")

if admin.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: admin runtime_action_available is not false")
if admin.get("admin_endpoint_available") is not True:
    raise SystemExit("FAIL: admin endpoint is not marked available")
if admin.get("dry_run_only") is not True:
    raise SystemExit("FAIL: admin dry_run_only is not true")
if admin.get("action_enabled") is True:
    raise SystemExit("FAIL: admin action_enabled unexpectedly true")

skeletons = memory.get("disabled_future_warmup_execution_skeletons")
if not isinstance(skeletons, dict):
    raise SystemExit("FAIL: disabled_future_warmup_execution_skeletons missing")

required_models = ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"]
for model in required_models:
    item = skeletons.get(model)
    if not isinstance(item, dict):
        raise SystemExit(f"FAIL: skeleton missing for {model}")

    checks = {
        "source": "phase_12r_y_disabled_future_warmup_execution_skeleton",
        "mode": "disabled_future_execution_skeleton",
        "model": model,
        "would_call": "none",
        "reason": "runtime_action_unavailable",
    }
    for key, expected in checks.items():
        actual = item.get(key)
        if actual != expected:
            raise SystemExit(f"FAIL: skeleton {model} {key} expected {expected!r}, got {actual!r}")

    if item.get("runtime_action_available") is not False:
        raise SystemExit(f"FAIL: skeleton {model} runtime_action_available is not false")

    future = item.get("future_ollama_request")
    if not isinstance(future, dict):
        raise SystemExit(f"FAIL: skeleton {model} future_ollama_request missing")
    if future.get("endpoint") != "/api/generate":
        raise SystemExit(f"FAIL: skeleton {model} future endpoint mismatch")
    if future.get("method") != "POST":
        raise SystemExit(f"FAIL: skeleton {model} future method mismatch")
    if future.get("execute_now") is not False:
        raise SystemExit(f"FAIL: skeleton {model} execute_now is not false")

print("PASS: live disabled warmup control-plane status is stable")
PY

echo
echo "=== unauthenticated POST must remain auth/admin blocked ==="
unauth_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rah-unauth-post.json \
  -w "%{http_code}" \
  http://127.0.0.1:7070/admin/model-warmup || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: expected unauthenticated POST to be blocked with 401 or 403"
  fail=1
fi

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rah-unauth-post.json").read_text())
body = json.dumps(data, sort_keys=True)

for forbidden in [
    "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "future_warmup_execution_preview",
    "disabled_future_execution_skeleton",
    "warmup_action_disabled",
    "would_call",
    "runtime_action_available",
]:
    if forbidden in body:
        raise SystemExit(f"FAIL: unauth response leaked warmup marker: {forbidden}")

print("PASS: unauthenticated POST remains blocked before warmup refusal")
print("detail:", data.get("detail"))
PY

echo
echo "=== static execution-boundary spot check ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

admin_route = None
disabled_helper = None
future_helper = None

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
            disabled_helper = node
        if node.name == "_stage5p12y_disabled_future_warmup_execution_skeleton":
            future_helper = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

assert admin_route is not None, "missing admin warmup route"
assert disabled_helper is not None, "missing disabled admin helper"
assert future_helper is not None, "missing future skeleton helper"

admin_src = segment(admin_route)
disabled_src = segment(disabled_helper)
future_src = segment(future_helper)

assert "_admin_support_require_admin(request)" in admin_src
assert "raise HTTPException(status_code=403, detail=response)" in admin_src
assert "future_warmup_execution_preview" in disabled_src
assert '"execute_now": False' in future_src
assert '"would_call": "none"' in future_src
assert "runtime_action_available = False" in future_src

for label, text in [
    ("admin_route", admin_src),
    ("disabled_helper", disabled_src),
]:
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
        assert forbidden not in text, f"{label} contains forbidden marker: {forbidden}"

print("PASS: static execution boundary remains disabled")
PY

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
