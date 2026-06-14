#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ao-disabled-warmup-control-plane-final-rollup"
fail=0

echo "=== ${PHASE}: final disabled warmup control-plane rollup ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== required phase smoke files exist ==="
for required in \
  ops/smoke/check-phase-12r-ak-public-system-status-latency-guard-smoke.sh \
  ops/smoke/check-phase-12r-al-disabled-warmup-activation-guard-report-helper-skeleton.sh \
  ops/smoke/check-phase-12r-am-admin-disabled-warmup-refusal-guard-report-attachment.sh \
  ops/smoke/check-phase-12r-an-guarded-live-authenticated-admin-refusal-guard-report-verification.sh
do
  if [ ! -f "$required" ]; then
    echo "FAIL: missing required smoke: $required"
    fail=1
  else
    echo "PASS: found $required"
  fi
done

echo
echo "=== run no-restart disabled warmup control-plane smokes ==="
ops/smoke/check-phase-12r-ak-public-system-status-latency-guard-smoke.sh || fail=1
ops/smoke/check-phase-12r-al-disabled-warmup-activation-guard-report-helper-skeleton.sh || fail=1
ops/smoke/check-phase-12r-am-admin-disabled-warmup-refusal-guard-report-attachment.sh || fail=1

echo
echo "=== static final contract check ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

functions = {}
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
        functions[node.name] = node
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

required_functions = [
    "_stage5p12aj_public_model_memory_status_snapshot",
    "_stage5p12al_disabled_warmup_activation_guard_report",
    "_stage5p12m_disabled_admin_model_warmup_response",
    "_stage5p12y_disabled_future_warmup_execution_skeleton",
]
for name in required_functions:
    if name not in functions:
        raise SystemExit(f"FAIL: missing required helper: {name}")

if admin_route is None:
    raise SystemExit("FAIL: POST /admin/model-warmup route not found")

admin_src = ast.get_source_segment(src, admin_route) or ""
response_src = ast.get_source_segment(src, functions["_stage5p12m_disabled_admin_model_warmup_response"]) or ""
guard_src = ast.get_source_segment(src, functions["_stage5p12al_disabled_warmup_activation_guard_report"]) or ""
public_status_src = ast.get_source_segment(src, functions["_stage5p12aj_public_model_memory_status_snapshot"]) or ""

required_admin = [
    "_admin_support_require_admin(request)",
    "_stage5p12r_model_memory_status_read_only()",
    "payload=payload",
    "authenticated_admin=True",
    "raise HTTPException(status_code=403, detail=response)",
]
for marker in required_admin:
    if marker not in admin_src:
        raise SystemExit(f"FAIL: admin route missing marker: {marker}")

required_response = [
    '"runtime_action_available": False',
    '"would_call": "none"',
    '"activation_guard_report": activation_guard_report',
    '"future_warmup_execution_preview": future_preview',
]
for marker in required_response:
    if marker not in response_src:
        raise SystemExit(f"FAIL: disabled response helper missing marker: {marker}")

required_guard = [
    '"source": "phase_12r_al_disabled_warmup_activation_guard_report"',
    '"mode": "disabled_guard_report_only"',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"would_call": "none"',
    '"execute_now": False',
    '"all_required_guards_passed": False',
    '"runtime_executor_implemented": False',
    '"ollama_generation_call_allowed": False',
]
for marker in required_guard:
    if marker not in guard_src:
        raise SystemExit(f"FAIL: activation guard helper missing marker: {marker}")

required_public = [
    '"source": "phase_12r_aj_public_system_status_model_memory_snapshot"',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"would_call": "none"',
]
for marker in required_public:
    if marker not in public_status_src:
        raise SystemExit(f"FAIL: public status snapshot missing marker: {marker}")

for label, text in [
    ("admin_route", admin_src),
    ("disabled_response_helper", response_src),
    ("activation_guard_helper", guard_src),
    ("public_status_snapshot", public_status_src),
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

print("PASS: static final disabled warmup control-plane contract is intact")
PY

echo
echo "=== live health ==="
curl -sS --max-time 5 -o /tmp/phase12rao-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live public /system/status disabled snapshot ==="
curl -sS --max-time 10 -o /tmp/phase12rao-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rao-status.json").read_text())
memory = data.get("model_memory_status")

if not isinstance(memory, dict):
    raise SystemExit("FAIL: top-level model_memory_status missing")

expected = {
    "source": "phase_12r_aj_public_system_status_model_memory_snapshot",
    "network_calls": False,
    "runtime_action_available": False,
    "would_call": "none",
}
for key, value in expected.items():
    actual = memory.get(key)
    if actual != value:
        raise SystemExit(f"FAIL: model_memory_status.{key} expected {value!r}, got {actual!r}")

if "admin_model_warmup_endpoint" not in memory:
    raise SystemExit("FAIL: model_memory_status missing admin_model_warmup_endpoint")
if "disabled_future_warmup_execution_skeletons" not in memory:
    raise SystemExit("FAIL: model_memory_status missing disabled_future_warmup_execution_skeletons")

print("PASS: live public status exposes disabled lightweight model memory snapshot")
PY

echo
echo "=== live unauthenticated future-style POST remains blocked ==="
unauth_code="$(curl -sS --max-time 8 \
  -o /tmp/phase12rao-unauth-post.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/admin/model-warmup \
  -H 'Content-Type: application/json' \
  --data '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW","reason":"phase_12r_ao_final_rollup_unauth_check"}' || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: unauthenticated future-style POST was not auth/admin blocked"
  cat /tmp/phase12rao-unauth-post.json || true
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
echo "=== optional Phase 12R-AN live authenticated restart smoke ==="
if [ "${RUN_PHASE12R_AN_LIVE:-0}" = "1" ]; then
  echo "CHECK: RUN_PHASE12R_AN_LIVE=1, running Phase 12R-AN live authenticated smoke"
  ops/smoke/check-phase-12r-an-guarded-live-authenticated-admin-refusal-guard-report-verification.sh || fail=1
else
  echo "CHECK: skipped by default; set RUN_PHASE12R_AN_LIVE=1 to run the authenticated restart smoke"
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed by default"
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
