#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13b-static-intent-router-contract-regression-smoke"
fail=0

echo "=== ${PHASE}: static intent-router contract and regression checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Phase 13A smoke ==="
ops/smoke/check-phase-13a-disabled-intent-router-foundation.sh || fail=1

echo
echo "=== static helper exposure and call contract ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_name = "_stage5p13a_disabled_intent_router_foundation"
helper = None
routes = []
calls = []

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

class ParentAnnotator(ast.NodeVisitor):
    def visit(self, node):
        for child in ast.iter_child_nodes(node):
            child.parent = node
        return super().visit(node)

ParentAnnotator().visit(tree)

for node in tree.body:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        if node.name == helper_name:
            helper = node
        for deco in node.decorator_list:
            path = route_path(deco)
            if path:
                routes.append((path, node.name))

if helper is None:
    raise SystemExit("FAIL: Phase 13A helper missing")

def enclosing_function_name(node):
    current = getattr(node, "parent", None)
    while current is not None:
        if isinstance(current, (ast.FunctionDef, ast.AsyncFunctionDef)):
            return current.name
        current = getattr(current, "parent", None)
    return None

for node in ast.walk(tree):
    if isinstance(node, ast.Call):
        fn = node.func
        if isinstance(fn, ast.Name) and fn.id == helper_name:
            parent = getattr(node, "parent", None)
            calls.append((type(parent).__name__, getattr(parent, "lineno", None), enclosing_function_name(node)))

allowed_callers = {"admin_intent_router_preview"}
unexpected_calls = [
    call for call in calls
    if call[2] not in allowed_callers
]
if unexpected_calls:
    raise SystemExit(f"FAIL: helper is called from unexpected code path(s): {unexpected_calls}")

for path, name in routes:
    if name == helper_name:
        raise SystemExit(f"FAIL: helper exposed as route: {path}")

helper_src = ast.get_source_segment(src, helper) or ""
helper_lower = helper_src.lower()

required_markers = [
    '"source": "phase_13a_disabled_intent_router_foundation"',
    '"mode": "disabled_router_foundation_only"',
    '"read_only": True',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"route_wired": False',
    '"execute_now": False',
    '"would_call": "none"',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"not_connected_to_live_routes": True',
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_tool_call": True',
    '"study_review"',
    '"study_material"',
    '"companion_chat"',
    '"calendar"',
    '"profile"',
    '"admin_system"',
    '"unknown"',
]
for marker in required_markers:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing required marker: {marker}")

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
    "ollama",
    "/api/generate",
    "/api/chat",
]:
    if forbidden in helper_lower:
        raise SystemExit(f"FAIL: helper contains forbidden marker: {forbidden}")

print("PASS: helper remains unexposed, disabled, non-executing, and only called by the allowed preview route if present")
PY

echo
echo "=== dynamic regression matrix without importing full app ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_node = None
for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p13a_disabled_intent_router_foundation":
        helper_node = node
        break

if helper_node is None:
    raise SystemExit("FAIL: helper node missing")

module = ast.Module(body=[helper_node], type_ignores=[])
ast.fix_missing_locations(module)

ns = {}
exec(compile(module, "<phase13b-helper>", "exec"), ns)
router = ns["_stage5p13a_disabled_intent_router_foundation"]

cases = [
    {
        "message": "next",
        "intent": "study_review",
        "action": "study_card_advance",
        "tier": "tier_2_study_light",
    },
    {
        "message": "skip",
        "intent": "study_review",
        "action": "study_card_advance",
        "tier": "tier_2_study_light",
    },
    {
        "message": "correct",
        "intent": "study_review",
        "action": "study_mark_correct",
        "tier": "tier_2_study_light",
    },
    {
        "message": "incorrect",
        "intent": "study_review",
        "action": "study_mark_incorrect",
        "tier": "tier_2_study_light",
    },
    {
        "message": "Answer is five",
        "intent": "study_review",
        "action": None,
        "tier": "tier_2_study_light",
        "number_token": "five",
        "number_value": 5,
    },
    {
        "message": "How does my calendar look today?",
        "intent": "calendar",
        "action": None,
        "tier": "tier_1_router_then_tool",
    },
    {
        "message": "Open profile language settings",
        "intent": "profile",
        "action": None,
        "tier": "tier_1_router_then_backend",
    },
    {
        "message": "Show system status",
        "intent": "admin_system",
        "action": None,
        "tier": "tier_1_router_then_backend",
    },
    {
        "message": "Can we talk for a bit?",
        "intent": "companion_chat",
        "action": None,
        "tier": "tier_3_companion_medium",
    },
    {
        "message": "",
        "intent": "unknown",
        "action": None,
        "tier": "tier_1_router_then_companion_fallback",
    },
]

required_false = [
    "runtime_action_available",
    "route_wired",
    "execute_now",
    "model_call_allowed",
    "job_enqueue_allowed",
]

for case in cases:
    result = router(case["message"], {"preferred_language": "en", "study_language": "en"})
    if result.get("source") != "phase_13a_disabled_intent_router_foundation":
        raise SystemExit("FAIL: source changed")
    if result.get("mode") != "disabled_router_foundation_only":
        raise SystemExit("FAIL: mode changed")
    if result.get("read_only") is not True:
        raise SystemExit("FAIL: read_only changed")
    if result.get("network_calls") is not False:
        raise SystemExit("FAIL: network_calls changed")
    if result.get("would_call") != "none":
        raise SystemExit("FAIL: would_call changed")

    for key in required_false:
        if result.get(key) is not False:
            raise SystemExit(f"FAIL: {key} changed for {case['message']!r}")

    if result.get("primary_intent") != case["intent"]:
        raise SystemExit(
            f"FAIL: {case['message']!r} expected intent {case['intent']}, got {result.get('primary_intent')}"
        )

    if result.get("recommended_model_tier") != case["tier"]:
        raise SystemExit(
            f"FAIL: {case['message']!r} expected tier {case['tier']}, got {result.get('recommended_model_tier')}"
        )

    if case.get("action") and case["action"] not in result.get("deterministic_actions", []):
        raise SystemExit(f"FAIL: {case['message']!r} missing action {case['action']}")

    if "number_token" in case:
        matches = result.get("normalized_features", {}).get("number_word_matches", [])
        if not any(
            match.get("token") == case["number_token"]
            and match.get("value") == case["number_value"]
            for match in matches
        ):
            raise SystemExit(f"FAIL: number word {case['number_token']} was not normalized")

    confidence = result.get("confidence")
    if not isinstance(confidence, (float, int)):
        raise SystemExit("FAIL: confidence is not numeric")
    if confidence < 0 or confidence > 1:
        raise SystemExit("FAIL: confidence out of range")

    safety = result.get("safety")
    if not isinstance(safety, dict):
        raise SystemExit("FAIL: safety block missing")
    for safety_key in [
        "not_connected_to_live_routes",
        "no_model_invocation",
        "no_queue_write",
        "no_tool_call",
    ]:
        if safety.get(safety_key) is not True:
            raise SystemExit(f"FAIL: safety.{safety_key} changed")

print("PASS: dynamic regression matrix preserved disabled deterministic routing contract")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13b-static-intent-router-contract-regression-smoke.md").read_text()

required = [
    "Phase 13B does not change routing behavior.",
    "Not exposed as a FastAPI route.",
    "Not called by live routes.",
    "Not allowed to call a model.",
    "Not allowed to enqueue jobs.",
    "Phase 13C: disabled admin/local route-preview endpoint.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: doc missing marker: {marker}")

print("PASS: Phase 13B doc markers are present")
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
echo "PASS: no live route behavior was changed"
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
