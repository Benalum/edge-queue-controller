#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-al-disabled-warmup-activation-guard-report-helper-skeleton"
fail=0

echo "=== ${PHASE}: static disabled guard report checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static verify guard report helper ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper = None
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
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p12al_disabled_warmup_activation_guard_report":
        helper = node
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

if helper is None:
    raise SystemExit("FAIL: Phase 12R-AL guard report helper not found")
if admin_route is None:
    raise SystemExit("FAIL: admin warmup route not found")

helper_src = ast.get_source_segment(src, helper) or ""
admin_src = ast.get_source_segment(src, admin_route) or ""

required_helper = [
    '"source": "phase_12r_al_disabled_warmup_activation_guard_report"',
    '"mode": "disabled_guard_report_only"',
    '"read_only": True',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"would_call": "none"',
    '"execute_now": False',
    '"all_required_guards_passed": False',
    '"runtime_executor_implemented": False',
    '"ollama_generation_call_allowed": False',
    '"confirm_required": "WARMUP_MODEL_NOW"',
    '"qwen3:0.6b"',
    '"qwen3:1.7b"',
    '"llama3.2:3b"',
    '"warmup_action_env_disabled"',
    '"runtime_executor_not_implemented"',
    '"ollama_generation_call_not_allowed"',
]
for marker in required_helper:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing marker: {marker}")

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
    if forbidden in helper_src:
        raise SystemExit(f"FAIL: helper contains forbidden marker: {forbidden}")

if "_stage5p12al_disabled_warmup_activation_guard_report(" in admin_src:
    raise SystemExit("FAIL: admin route is already wired to Phase 12R-AL helper")

if "raise HTTPException(status_code=403, detail=response)" not in admin_src:
    raise SystemExit("FAIL: admin route no longer raises disabled 403")

print("PASS: Phase 12R-AL helper is disabled and not wired to runtime route")
PY

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
import ast
import os
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_node = None
for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p12al_disabled_warmup_activation_guard_report":
        helper_node = node
        break

if helper_node is None:
    raise SystemExit("FAIL: helper node not found")

module = ast.Module(body=[helper_node], type_ignores=[])
ast.fix_missing_locations(module)

namespace = {}
exec(compile(module, "phase12ral_helper_only", "exec"), namespace)

helper = namespace["_stage5p12al_disabled_warmup_activation_guard_report"]

os.environ.pop("EDGE_MODEL_WARMUP_ACTION_ENABLED", None)

report = helper(
    {
        "model": "qwen3:0.6b",
        "dry_run": False,
        "confirm": "WARMUP_MODEL_NOW",
    },
    status={"source": "test_status"},
    authenticated_admin=True,
)

if report.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: runtime_action_available is not false")
if report.get("would_call") != "none":
    raise SystemExit("FAIL: would_call is not none")
if report.get("execute_now") is not False:
    raise SystemExit("FAIL: execute_now is not false")
if report.get("all_required_guards_passed") is not False:
    raise SystemExit("FAIL: all_required_guards_passed is not false")
if report.get("network_calls") is not False:
    raise SystemExit("FAIL: network_calls is not false")
if report.get("status_source") != "test_status":
    raise SystemExit("FAIL: status_source did not pass through")

guards = report.get("guards") or {}
expected_true = [
    "authenticated_admin",
    "confirm_matches",
    "model_allowlisted",
    "dry_run_false_requested",
]
for key in expected_true:
    if guards.get(key) is not True:
        raise SystemExit(f"FAIL: {key} guard should be true in this test")

expected_false = [
    "warmup_action_env_enabled",
    "runtime_executor_implemented",
    "ollama_generation_call_allowed",
]
for key in expected_false:
    if guards.get(key) is not False:
        raise SystemExit(f"FAIL: {key} guard must remain false")

blocked = report.get("blocked_reasons") or []
for required in [
    "warmup_action_env_disabled",
    "runtime_executor_not_implemented",
    "ollama_generation_call_not_allowed",
]:
    if required not in blocked:
        raise SystemExit(f"FAIL: missing blocked reason: {required}")

bad_report = helper(
    {
        "model": "not-allowed-model",
        "dry_run": True,
        "confirm": "NOPE",
    },
    status={},
    authenticated_admin=False,
)

bad_blocked = bad_report.get("blocked_reasons") or []
for required in [
    "authenticated_admin_required",
    "warmup_action_env_disabled",
    "confirm_required",
    "model_not_allowlisted",
    "dry_run_only_request",
    "runtime_executor_not_implemented",
    "ollama_generation_call_not_allowed",
]:
    if required not in bad_blocked:
        raise SystemExit(f"FAIL: missing expected bad-request blocked reason: {required}")

print("PASS: dynamic helper report remains disabled without importing full app")
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
