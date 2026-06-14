#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ai-inspect-only-warmup-execution-activation-contract"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: inspect-only activation contract checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== run disabled control-plane rollup ==="
ops/smoke/check-phase-12r-ah-disabled-warmup-control-plane-readiness-rollup.sh || fail=1

echo
echo "=== verify activation contract doc exists ==="
test -f "$DOC" || fail=1
grep -q 'EDGE_MODEL_WARMUP_ACTION_ENABLED=1' "$DOC" || fail=1
grep -q 'WARMUP_MODEL_NOW' "$DOC" || fail=1
grep -q '/api/generate' "$DOC" || fail=1
grep -q 'No /api/chat warmup path is approved' "$DOC" || fail=1

echo
echo "=== static execution boundary must remain disabled ==="
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
        "urllib.request",
        "requests.",
        "subprocess",
        "systemctl",
        "_forward_ollama_chat_job_direct",
        "tick_ollama_direct",
    ]:
        assert forbidden not in text, f"{label} contains forbidden execution marker: {forbidden}"

assert '"/api/generate"' in future_src
assert '"execute_now": False' in future_src
assert "urlopen" not in future_src
assert "httpx." not in future_src
assert "requests." not in future_src
assert "subprocess" not in future_src

print("PASS: static warmup execution boundary remains inspect-only")
PY

echo
echo "=== live unauthenticated POST remains blocked before warmup refusal ==="
unauth_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW"}' \
  -o /tmp/phase12rai-unauth-post.json \
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

data = json.loads(Path("/tmp/phase12rai-unauth-post.json").read_text())
body = json.dumps(data, sort_keys=True)

for forbidden in [
    "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "future_warmup_execution_preview",
    "disabled_future_execution_skeleton",
    "warmup_action_disabled",
    "would_call",
    "runtime_action_available",
    "WARMUP_MODEL_NOW",
]:
    if forbidden in body:
        raise SystemExit(f"FAIL: unauth response leaked warmup marker: {forbidden}")

print("PASS: unauthenticated confirm request remains blocked before warmup refusal")
print("detail:", data.get("detail"))
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
echo "PASS: no edge_controller.py runtime execution patch was required"
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
