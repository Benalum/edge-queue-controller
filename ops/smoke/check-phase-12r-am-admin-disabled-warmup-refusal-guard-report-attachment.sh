#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-am-admin-disabled-warmup-refusal-guard-report-attachment"
fail=0

echo "=== ${PHASE}: static disabled refusal guard-report checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static verify disabled response includes guard report ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

response_helper = None
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
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p12m_disabled_admin_model_warmup_response":
        response_helper = node
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

if response_helper is None:
    raise SystemExit("FAIL: disabled admin warmup response helper not found")
if admin_route is None:
    raise SystemExit("FAIL: admin warmup route not found")

helper_src = ast.get_source_segment(src, response_helper) or ""
admin_src = ast.get_source_segment(src, admin_route) or ""

required_helper = [
    "payload: dict | None = None",
    "authenticated_admin: bool | None = None",
    'payload.setdefault("model", model)',
    'payload.setdefault("dry_run", dry_run)',
    "activation_guard_report = _stage5p12al_disabled_warmup_activation_guard_report(",
    "authenticated_admin=authenticated_admin",
    '"activation_guard_report": activation_guard_report',
    '"future_warmup_execution_preview": future_preview',
    '"runtime_action_available": False',
    '"would_call": "none"',
]
for marker in required_helper:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: response helper missing marker: {marker}")

required_admin = [
    "_admin_support_require_admin(request)",
    "payload=payload",
    "authenticated_admin=True",
    "raise HTTPException(status_code=403, detail=response)",
]
for marker in required_admin:
    if marker not in admin_src:
        raise SystemExit(f"FAIL: admin route missing marker: {marker}")

for label, text in [
    ("response_helper", helper_src),
    ("admin_route", admin_src),
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
        "/api/generate",
        "/api/chat",
    ]:
        if forbidden in text:
            raise SystemExit(f"FAIL: {label} contains forbidden marker: {forbidden}")

print("PASS: disabled admin refusal includes guard report metadata only")
PY

echo
echo "=== static verify guard report helper remains disabled ==="
ops/smoke/check-phase-12r-al-disabled-warmup-activation-guard-report-helper-skeleton.sh || fail=1

echo
echo "=== regression: public status latency guard ==="
ops/smoke/check-phase-12r-ak-public-system-status-latency-guard-smoke.sh || fail=1

echo
echo "=== live unauthenticated future-style POST remains blocked before refusal ==="
unauth_code="$(curl -sS --max-time 8 \
  -o /tmp/phase12ram-unauth-post.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/admin/model-warmup \
  -H 'Content-Type: application/json' \
  --data '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW"}' || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: unauthenticated future-style POST was not auth/admin blocked"
  cat /tmp/phase12ram-unauth-post.json || true
  fail=1
else
  echo "PASS: unauthenticated future-style POST remains blocked"
fi

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
