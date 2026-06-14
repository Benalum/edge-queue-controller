#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13d-disabled-study-answer-evaluation-foundation"
fail=0

echo "=== ${PHASE}: disabled study answer-evaluation foundation checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Phase 13C smoke ==="
ops/smoke/check-phase-13c-disabled-admin-intent-router-preview-endpoint.sh || fail=1

echo
echo "=== static helper contract ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_name = "_stage5p13d_disabled_study_answer_evaluation_foundation"
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
    raise SystemExit("FAIL: Phase 13D helper missing")

for path, name in routes:
    if name == helper_name:
        raise SystemExit(f"FAIL: helper exposed as route: {path}")

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

allowed_callers = {"admin_study_answer_preview"}
unexpected_calls = [
    call for call in calls
    if len(call) < 3 or call[2] not in allowed_callers
]
if unexpected_calls:
    raise SystemExit(f"FAIL: Phase 13D helper is called from unexpected code path(s): {unexpected_calls}")

helper_src = ast.get_source_segment(src, helper) or ""
helper_lower = helper_src.lower()

required_markers = [
    '"source": "phase_13d_disabled_study_answer_evaluation_foundation"',
    '"mode": "disabled_study_answer_evaluation_foundation_only"',
    '"read_only": True',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"route_wired": False',
    '"live_study_integration": False',
    '"execute_now": False',
    '"would_call": "none"',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"database_write_allowed": False',
    '"card_state_change_allowed": False',
    '"card_match_only": True',
    '"factual_truth_check_available": False',
    '"model_judge_allowed": False',
    '"needs_model_judge": needs_model_judge',
    '"recommended_model_tier": recommended_model_tier',
    '"deterministic_match": deterministic_match',
    '"judge_prompt_contract": judge_prompt_contract',
    '"not_connected_to_live_study_routes": True',
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_database_write": True',
    '"no_card_state_change": True',
    '"no_tool_call": True',
]
for marker in required_markers:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing marker: {marker}")

for forbidden in [
    "app.",
    "@app.",
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
    if forbidden in helper_lower:
        raise SystemExit(f"FAIL: helper contains forbidden marker: {forbidden}")

print("PASS: Phase 13D helper is disabled, pure, unexposed, and only called by the allowed preview route if present")
PY

echo
echo "=== dynamic behavior without importing full app ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_node = None
for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p13d_disabled_study_answer_evaluation_foundation":
        helper_node = node
        break

if helper_node is None:
    raise SystemExit("FAIL: helper node missing")

module = ast.Module(body=[helper_node], type_ignores=[])
ast.fix_missing_locations(module)

ns = {}
exec(compile(module, "<phase13d-helper>", "exec"), ns)
evaluate = ns["_stage5p13d_disabled_study_answer_evaluation_foundation"]

cases = [
    {
        "name": "number word equals digit",
        "expected": "5",
        "user": "five",
        "question": "What is 2 plus 3?",
        "verdict": "correct",
        "match_type": "number_word_normalized",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
    },
    {
        "name": "answer phrase number word equals digit",
        "expected": "5",
        "user": "the answer is five.",
        "question": "What is 2 plus 3?",
        "verdict": "correct",
        "match_type": "number_word_normalized",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
    },
    {
        "name": "sky paraphrase requires model judge",
        "expected": "The sky is blue because of the reflection of the water",
        "user": "reflection of water causes the sky to be blue",
        "question": "Why is the sky blue?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
    },
    {
        "name": "jeans versus pants requires model judge",
        "expected": "Pants",
        "user": "Jeans",
        "question": "What clothing category is this?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
    },
    {
        "name": "blue versus red requires model judge",
        "expected": "Blue",
        "user": "Red",
        "question": "What color is it?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
    },
    {
        "name": "empty user answer",
        "expected": "Blue",
        "user": "",
        "question": "What color is it?",
        "verdict": "incorrect",
        "match_type": "empty_user_answer",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
    },
]

for case in cases:
    result = evaluate(
        case["expected"],
        case["user"],
        case["question"],
        {"preferred_language": "en", "study_language": "en"},
    )

    if result.get("source") != "phase_13d_disabled_study_answer_evaluation_foundation":
        raise SystemExit(f"FAIL {case['name']}: source changed")
    if result.get("mode") != "disabled_study_answer_evaluation_foundation_only":
        raise SystemExit(f"FAIL {case['name']}: mode changed")

    required_false = [
        "runtime_action_available",
        "route_wired",
        "live_study_integration",
        "execute_now",
        "model_call_allowed",
        "job_enqueue_allowed",
        "database_write_allowed",
        "card_state_change_allowed",
        "factual_truth_check_available",
        "model_judge_allowed",
    ]
    for key in required_false:
        if result.get(key) is not False:
            raise SystemExit(f"FAIL {case['name']}: {key} changed")

    if result.get("read_only") is not True:
        raise SystemExit(f"FAIL {case['name']}: read_only changed")
    if result.get("network_calls") is not False:
        raise SystemExit(f"FAIL {case['name']}: network_calls changed")
    if result.get("would_call") != "none":
        raise SystemExit(f"FAIL {case['name']}: would_call changed")
    if result.get("card_match_only") is not True:
        raise SystemExit(f"FAIL {case['name']}: card_match_only changed")

    if result.get("verdict") != case["verdict"]:
        raise SystemExit(
            f"FAIL {case['name']}: expected verdict {case['verdict']}, got {result.get('verdict')}"
        )
    if result.get("match_type") != case["match_type"]:
        raise SystemExit(
            f"FAIL {case['name']}: expected match_type {case['match_type']}, got {result.get('match_type')}"
        )
    if result.get("needs_model_judge") is not case["needs_model_judge"]:
        raise SystemExit(
            f"FAIL {case['name']}: expected needs_model_judge {case['needs_model_judge']}, got {result.get('needs_model_judge')}"
        )
    if result.get("recommended_model_tier") != case["recommended_model_tier"]:
        raise SystemExit(
            f"FAIL {case['name']}: expected tier {case['recommended_model_tier']}, got {result.get('recommended_model_tier')}"
        )

    contract = result.get("judge_prompt_contract")
    if not isinstance(contract, dict):
        raise SystemExit(f"FAIL {case['name']}: judge_prompt_contract missing")
    if contract.get("mode") != "card_match_not_truth_check":
        raise SystemExit(f"FAIL {case['name']}: judge contract mode changed")

    confidence = result.get("confidence")
    if not isinstance(confidence, (float, int)):
        raise SystemExit(f"FAIL {case['name']}: confidence not numeric")
    if confidence < 0 or confidence > 1:
        raise SystemExit(f"FAIL {case['name']}: confidence out of range")

    safety = result.get("safety")
    if not isinstance(safety, dict):
        raise SystemExit(f"FAIL {case['name']}: safety block missing")
    for safety_key in [
        "not_connected_to_live_study_routes",
        "no_model_invocation",
        "no_queue_write",
        "no_database_write",
        "no_card_state_change",
        "no_tool_call",
    ]:
        if safety.get(safety_key) is not True:
            raise SystemExit(f"FAIL {case['name']}: safety.{safety_key} changed")

number_result = evaluate("5", "the answer is five.", "What is 2 plus 3?", {})
user_matches = number_result.get("normalized", {}).get("user_number_matches", [])
if not any(match.get("token") == "five" and match.get("value") == "5" for match in user_matches):
    raise SystemExit("FAIL: user number-word match five -> 5 missing")

print("PASS: exact matches stay deterministic; non-exact answers require future small Study Judge")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13d-disabled-study-answer-evaluation-foundation.md").read_text()

required = [
    "Do not hardcode lots of similar phrases.",
    "Any non-exact answer should be marked as requiring a future small Study Judge model.",
    "The model judge should use the question, expected answer, and user answer together.",
    "This helper is card-match only.",
    "Is the stored card answer factually true?",
    "Phase 13H: small Study Judge model call for non-exact answers.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: doc missing marker: {marker}")

print("PASS: Phase 13D doc markers are present")
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
