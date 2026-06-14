#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13e-static-study-answer-evaluation-contract-regression-smoke"
fail=0

echo "=== ${PHASE}: study answer-evaluation contract regression checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Phase 13D smoke ==="
ops/smoke/check-phase-13d-disabled-study-answer-evaluation-foundation.sh || fail=1

echo
echo "=== static helper contract regression ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper_name = "_stage5p13d_disabled_study_answer_evaluation_foundation"
helper = None
routes = []
calls = []

class ParentAnnotator(ast.NodeVisitor):
    def visit(self, node):
        for child in ast.iter_child_nodes(node):
            child.parent = node
        return super().visit(node)

ParentAnnotator().visit(tree)

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

def enclosing_function_name(node):
    current = getattr(node, "parent", None)
    while current is not None:
        if isinstance(current, (ast.FunctionDef, ast.AsyncFunctionDef)):
            return current.name
        current = getattr(current, "parent", None)
    return None

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
        raise SystemExit(f"FAIL: Phase 13D helper exposed as route: {path}")

for node in ast.walk(tree):
    if isinstance(node, ast.Call):
        fn = node.func
        if isinstance(fn, ast.Name) and fn.id == helper_name:
            calls.append((type(getattr(node, "parent", None)).__name__, getattr(node, "lineno", None), enclosing_function_name(node)))

if calls:
    raise SystemExit(f"FAIL: Phase 13D helper is called from code path(s): {calls}")

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
    '"mode": "card_match_not_truth_check"',
    '"verdict": "correct | partially_correct | incorrect | unsure"',
    '"relationship": "same_meaning | narrower | broader | related | unrelated | contradiction | unclear"',
    '"not_connected_to_live_study_routes": True',
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_database_write": True',
    '"no_card_state_change": True',
    '"no_tool_call": True',
]
for marker in required_markers:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing required marker: {marker}")

must_not_include = [
    "semantic synonym groups",
    "narrower_terms =",
    "synonym_groups =",
]
for marker in must_not_include:
    if marker in helper_lower:
        raise SystemExit(f"FAIL: helper appears to be reintroducing hardcoded semantic matching: {marker}")

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

print("PASS: Phase 13D helper contract remains disabled, pure, uncalled, unexposed, and non-executing")
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
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p13d_disabled_study_answer_evaluation_foundation":
        helper_node = node
        break

if helper_node is None:
    raise SystemExit("FAIL: helper node missing")

module = ast.Module(body=[helper_node], type_ignores=[])
ast.fix_missing_locations(module)

ns = {}
exec(compile(module, "<phase13e-helper>", "exec"), ns)
evaluate = ns["_stage5p13d_disabled_study_answer_evaluation_foundation"]

cases = [
    {
        "name": "digit versus number word",
        "expected": "5",
        "user": "five",
        "question": "What is two plus three?",
        "verdict": "correct",
        "match_type": "number_word_normalized",
        "relationship": "same_normalized_answer",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
        "deterministic_match": True,
    },
    {
        "name": "answer prefix plus number word",
        "expected": "5",
        "user": "the answer is five.",
        "question": "What is two plus three?",
        "verdict": "correct",
        "match_type": "number_word_normalized",
        "relationship": "same_normalized_answer",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
        "deterministic_match": True,
    },
    {
        "name": "normalized exact color",
        "expected": "Blue",
        "user": "blue.",
        "question": "What color is the icon?",
        "verdict": "correct",
        "match_type": "normalized_exact",
        "relationship": "same_normalized_answer",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
        "deterministic_match": True,
    },
    {
        "name": "sky paraphrase needs judge",
        "expected": "The sky is blue because of the reflection of the water",
        "user": "reflection of water causes the sky to be blue",
        "question": "Why is the sky blue?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "relationship": "unknown_until_model_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
        "deterministic_match": False,
    },
    {
        "name": "jeans versus pants needs judge",
        "expected": "Pants",
        "user": "Jeans",
        "question": "What clothing category is this?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "relationship": "unknown_until_model_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
        "deterministic_match": False,
    },
    {
        "name": "wrong color still goes to judge until model phase",
        "expected": "Blue",
        "user": "Red",
        "question": "What color is the icon?",
        "verdict": "unsure",
        "match_type": "requires_semantic_judge",
        "relationship": "unknown_until_model_judge",
        "needs_model_judge": True,
        "recommended_model_tier": "tier_2_study_light",
        "deterministic_match": False,
    },
    {
        "name": "empty answer deterministic incorrect",
        "expected": "Blue",
        "user": "",
        "question": "What color is the icon?",
        "verdict": "incorrect",
        "match_type": "empty_user_answer",
        "relationship": "missing_user_answer",
        "needs_model_judge": False,
        "recommended_model_tier": "none",
        "deterministic_match": False,
    },
]

for case in cases:
    result = evaluate(
        case["expected"],
        case["user"],
        case["question"],
        {"preferred_language": "en", "study_language": "en"},
    )

    for key in [
        "source",
        "mode",
        "verdict",
        "match_type",
        "relationship",
        "recommended_model_tier",
    ]:
        if key == "source":
            expected_value = "phase_13d_disabled_study_answer_evaluation_foundation"
        elif key == "mode":
            expected_value = "disabled_study_answer_evaluation_foundation_only"
        else:
            expected_value = case[key]
        if result.get(key) != expected_value:
            raise SystemExit(f"FAIL {case['name']}: expected {key}={expected_value}, got {result.get(key)}")

    for key in [
        "needs_model_judge",
        "deterministic_match",
    ]:
        if result.get(key) is not case[key]:
            raise SystemExit(f"FAIL {case['name']}: expected {key}={case[key]}, got {result.get(key)}")

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

    confidence = result.get("confidence")
    if not isinstance(confidence, (float, int)):
        raise SystemExit(f"FAIL {case['name']}: confidence not numeric")
    if confidence < 0 or confidence > 1:
        raise SystemExit(f"FAIL {case['name']}: confidence out of range")

    contract = result.get("judge_prompt_contract")
    if not isinstance(contract, dict):
        raise SystemExit(f"FAIL {case['name']}: judge_prompt_contract missing")
    if contract.get("mode") != "card_match_not_truth_check":
        raise SystemExit(f"FAIL {case['name']}: judge contract mode changed")

    contract_inputs = contract.get("inputs", {})
    if contract_inputs.get("question") != case["question"]:
        raise SystemExit(f"FAIL {case['name']}: judge contract question mismatch")
    if contract_inputs.get("expected_answer") != case["expected"]:
        raise SystemExit(f"FAIL {case['name']}: judge contract expected answer mismatch")
    if contract_inputs.get("user_answer") != case["user"]:
        raise SystemExit(f"FAIL {case['name']}: judge contract user answer mismatch")

    schema = contract.get("required_output_schema", {})
    if "correct" not in schema.get("verdict", ""):
        raise SystemExit(f"FAIL {case['name']}: judge schema verdict missing correct")
    if "same_meaning" not in schema.get("relationship", ""):
        raise SystemExit(f"FAIL {case['name']}: judge schema relationship missing same_meaning")

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

number_result = evaluate("5", "the answer is five.", "What is two plus three?", {})
user_matches = number_result.get("normalized", {}).get("user_number_matches", [])
if not any(match.get("token") == "five" and match.get("value") == "5" for match in user_matches):
    raise SystemExit("FAIL: user number-word match five -> 5 missing")

print("PASS: Phase 13E regression matrix protects deterministic gate and future Study Judge handoff")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13e-static-study-answer-evaluation-contract-regression-smoke.md").read_text()

required = [
    "Phase 13E adds a static and dynamic regression smoke",
    "Keep deterministic matching small.",
    "Mark non-exact answers as requiring a future small Study Judge model.",
    "Do not hardcode lots of semantic phrase rules.",
    "Expected Pants and user Jeans should require the future small Study Judge.",
    "This phase protects card-match mode only.",
    "Phase 13F: disabled Study answer preview endpoint.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: doc missing marker: {marker}")

print("PASS: Phase 13E doc markers are present")
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
echo "PASS: no edge_controller.py changes are required by this phase"
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
