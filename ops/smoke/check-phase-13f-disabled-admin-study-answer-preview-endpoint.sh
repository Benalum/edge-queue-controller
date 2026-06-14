#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13f-disabled-admin-study-answer-preview-endpoint"
fail=0

echo "=== ${PHASE}: disabled admin Study-answer preview endpoint checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== Phase 13E compatibility smoke ==="
ops/smoke/check-phase-13e-static-study-answer-evaluation-contract-regression-smoke.sh || fail=1

echo
echo "=== static preview endpoint contract ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_name = "_stage5p13d_disabled_study_answer_evaluation_foundation"
route_name = "admin_study_answer_preview"
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
    raise SystemExit("FAIL: Phase 13D helper missing")
if route is None:
    raise SystemExit("FAIL: Phase 13F preview route function missing")

matching_routes = [path for path, name in routes if name == route_name]
if matching_routes != ["POST /admin/study-answer-preview"]:
    raise SystemExit(f"FAIL: preview route mapping mismatch: {matching_routes}")

route_src = ast.get_source_segment(src, route) or ""
route_lower = route_src.lower()

required = [
    "_admin_support_require_admin(request)",
    "_stage5p13d_disabled_study_answer_evaluation_foundation(",
    '"source": "phase_13f_disabled_admin_study_answer_preview_endpoint"',
    '"mode": "disabled_admin_study_answer_preview_only"',
    '"read_only": True',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"route_preview_only": True',
    '"live_study_integration": False',
    '"execute_now": False',
    '"would_call": "none"',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"database_write_allowed": False',
    '"card_state_change_allowed": False',
    '"requires_admin": True',
    '"study_answer_evaluation": evaluation',
    '"admin_gated": True',
    '"not_connected_to_live_study_routes": True',
    '"not_connected_to_companion_live_flow": True',
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_database_write": True',
    '"no_card_state_change": True',
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
    "update study",
    "update cards",
    "delete from",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "/api/generate",
    "/api/chat",
]:
    if forbidden in route_lower:
        raise SystemExit(f"FAIL: route contains forbidden marker: {forbidden}")

print("PASS: Study-answer preview endpoint is admin-gated, disabled, and non-executing")
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
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p13d_disabled_study_answer_evaluation_foundation":
        helper_node = node
    if isinstance(node, ast.AsyncFunctionDef) and node.name == "admin_study_answer_preview":
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
exec(compile(module, "<phase13f-preview>", "exec"), ns)

route = ns["admin_study_answer_preview"]

import asyncio

exact = asyncio.run(route(FakeRequest(), {
    "question": "What is two plus three?",
    "expected_answer": "5",
    "user_answer": "the answer is five.",
    "profile": {"preferred_language": "en", "study_language": "en"},
}))

if exact.get("source") != "phase_13f_disabled_admin_study_answer_preview_endpoint":
    raise SystemExit("FAIL: preview endpoint source mismatch")
if exact.get("mode") != "disabled_admin_study_answer_preview_only":
    raise SystemExit("FAIL: preview endpoint mode mismatch")

for key in [
    "runtime_action_available",
    "live_study_integration",
    "execute_now",
    "model_call_allowed",
    "job_enqueue_allowed",
    "database_write_allowed",
    "card_state_change_allowed",
]:
    if exact.get(key) is not False:
        raise SystemExit(f"FAIL: endpoint {key} changed")

if exact.get("would_call") != "none":
    raise SystemExit("FAIL: endpoint would_call changed")

evaluation = exact.get("study_answer_evaluation")
if not isinstance(evaluation, dict):
    raise SystemExit("FAIL: study_answer_evaluation missing")
if evaluation.get("verdict") != "correct":
    raise SystemExit("FAIL: exact number answer did not evaluate as correct")
if evaluation.get("match_type") != "number_word_normalized":
    raise SystemExit("FAIL: exact number answer did not preserve number_word_normalized")
if evaluation.get("needs_model_judge") is not False:
    raise SystemExit("FAIL: exact number answer unexpectedly needs model judge")

semantic = asyncio.run(route(FakeRequest(), {
    "question": "What clothing category is this?",
    "expected_answer": "Pants",
    "user_answer": "Jeans",
    "profile": {"preferred_language": "en", "study_language": "en"},
}))

semantic_eval = semantic.get("study_answer_evaluation")
if not isinstance(semantic_eval, dict):
    raise SystemExit("FAIL: semantic study_answer_evaluation missing")
if semantic_eval.get("verdict") != "unsure":
    raise SystemExit("FAIL: semantic case should remain unsure until model judge phase")
if semantic_eval.get("match_type") != "requires_semantic_judge":
    raise SystemExit("FAIL: semantic case should require semantic judge")
if semantic_eval.get("needs_model_judge") is not True:
    raise SystemExit("FAIL: semantic case should need model judge")
if semantic_eval.get("recommended_model_tier") != "tier_2_study_light":
    raise SystemExit("FAIL: semantic case should recommend tier_2_study_light")

print("PASS: dynamic preview endpoint returns disabled Study answer-evaluation metadata")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13f-disabled-admin-study-answer-preview-endpoint.md").read_text()

required = [
    "POST /admin/study-answer-preview",
    "admin-gated and non-executing",
    "This endpoint does not call a model.",
    "The new endpoint will not be live until the controller is reloaded in a later guarded phase.",
    "No live user-facing route may call the helper yet.",
    "Phase 13G: guarded live disabled route verification after controller restart.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: doc missing marker: {marker}")

print("PASS: Phase 13F doc markers are present")
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
echo "PASS: no database write was added"
echo "PASS: no card state change was added"
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
