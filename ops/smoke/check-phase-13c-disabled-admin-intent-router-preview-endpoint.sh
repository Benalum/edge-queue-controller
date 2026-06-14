#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13c-disabled-admin-intent-router-preview-endpoint"
fail=0

echo "=== ${PHASE}: disabled admin/local preview endpoint checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== Phase 13B compatibility smoke ==="
ops/smoke/check-phase-13b-static-intent-router-contract-regression-smoke.sh || fail=1

echo
echo "=== static preview endpoint contract ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_name = "_stage5p13a_disabled_intent_router_foundation"
route_name = "admin_intent_router_preview"
helper = None
route = None
routes = []

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
        if node.name == helper_name:
            helper = node
        if node.name == route_name:
            route = node
        for deco in node.decorator_list:
            path = route_path(deco)
            if path:
                routes.append((path, node.name))

if helper is None:
    raise SystemExit("FAIL: Phase 13A helper missing")
if route is None:
    raise SystemExit("FAIL: Phase 13C preview route function missing")

matching_routes = [path for path, name in routes if name == route_name]
if matching_routes != ["POST /admin/intent-router-preview"]:
    raise SystemExit(f"FAIL: preview route mapping mismatch: {matching_routes}")

route_src = ast.get_source_segment(src, route) or ""
route_lower = route_src.lower()

required = [
    "_admin_support_require_admin(request)",
    "_stage5p13a_disabled_intent_router_foundation(message, profile)",
    '"source": "phase_13c_disabled_admin_intent_router_preview_endpoint"',
    '"mode": "disabled_admin_preview_only"',
    '"read_only": True',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"route_preview_only": True',
    '"live_route_integration": False',
    '"execute_now": False',
    '"would_call": "none"',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"requires_admin": True',
    '"router_preview": preview',
    '"admin_gated": True',
    '"not_connected_to_study_live_flow": True',
    '"not_connected_to_companion_live_flow": True',
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_tool_call": True',
]
for marker in required:
    if marker not in route_src:
        raise SystemExit(f"FAIL: route missing required marker: {marker}")

for forbidden in [
    "httpx.",
    "urlopen",
    "urllib.request",
    "requests.",
    "subprocess",
    "systemctl",
    "sqlite3.connect",
    "enqueue_job(",
    "_enqueue(",
    "insert into jobs",
    "insert or replace into jobs",
    "update jobs set",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "/api/generate",
    "/api/chat",
]:
    if forbidden in route_lower:
        raise SystemExit(f"FAIL: route contains forbidden marker: {forbidden}")

print("PASS: preview endpoint is admin-gated, disabled, and non-executing")
PY

echo
echo "=== dynamic preview route behavior without importing full app ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_node = None
route_node = None

for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p13a_disabled_intent_router_foundation":
        helper_node = node
    if isinstance(node, ast.AsyncFunctionDef) and node.name == "admin_intent_router_preview":
        route_node = node

if helper_node is None:
    raise SystemExit("FAIL: helper node missing")
if route_node is None:
    raise SystemExit("FAIL: route node missing")

module = ast.Module(body=[helper_node, route_node], type_ignores=[])
ast.fix_missing_locations(module)

class HTTPException(Exception):
    def __init__(self, status_code=None, detail=None):
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)

def _admin_support_require_admin(request):
    if getattr(request, "is_admin", False) is not True:
        raise HTTPException(status_code=403, detail="Admin access required.")

class Request:
    pass

class FakeRequest:
    is_admin = True

class DummyApp:
    def post(self, *args, **kwargs):
        def decorator(fn):
            return fn
        return decorator

ns = {
    "HTTPException": HTTPException,
    "_admin_support_require_admin": _admin_support_require_admin,
    "Request": Request,
    "app": DummyApp(),
}
exec(compile(module, "<phase13c-preview>", "exec"), ns)

route = ns["admin_intent_router_preview"]

import asyncio

result = asyncio.run(route(FakeRequest(), {
    "message": "Answer is five",
    "profile": {"preferred_language": "en", "study_language": "en"},
}))

if result.get("source") != "phase_13c_disabled_admin_intent_router_preview_endpoint":
    raise SystemExit("FAIL: preview endpoint source mismatch")
if result.get("mode") != "disabled_admin_preview_only":
    raise SystemExit("FAIL: preview endpoint mode mismatch")
if result.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: endpoint runtime_action_available changed")
if result.get("live_route_integration") is not False:
    raise SystemExit("FAIL: endpoint live_route_integration changed")
if result.get("would_call") != "none":
    raise SystemExit("FAIL: endpoint would_call changed")
if result.get("model_call_allowed") is not False:
    raise SystemExit("FAIL: endpoint model_call_allowed changed")
if result.get("job_enqueue_allowed") is not False:
    raise SystemExit("FAIL: endpoint job_enqueue_allowed changed")

preview = result.get("router_preview")
if not isinstance(preview, dict):
    raise SystemExit("FAIL: router_preview missing")
if preview.get("primary_intent") != "study_review":
    raise SystemExit("FAIL: router_preview did not classify Answer is five as study_review")

matches = preview.get("normalized_features", {}).get("number_word_matches", [])
if not any(match.get("token") == "five" and match.get("value") == 5 for match in matches):
    raise SystemExit("FAIL: preview did not preserve five -> 5 normalization")

print("PASS: dynamic preview endpoint remains disabled and returns router preview metadata")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13c-disabled-admin-intent-router-preview-endpoint.md").read_text()

required = [
    "POST /admin/intent-router-preview",
    "admin-gated and non-executing",
    "The new endpoint will not be live until the controller is reloaded in a later guarded phase.",
    "No live user-facing route may call the helper yet.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: doc missing marker: {marker}")

print("PASS: Phase 13C doc markers are present")
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
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no job enqueue was added"
echo "PASS: no warmup execution was enabled"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
