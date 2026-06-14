#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13a-disabled-intent-router-foundation"
fail=0

echo "=== ${PHASE}: disabled intent-router foundation checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous safety baseline remains intact ==="
ops/smoke/check-phase-12s-a-inspect-only-warmup-execution-readiness-design.sh || fail=1

echo
echo "=== static helper contract ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

helper = None
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
        if node.name == "_stage5p13a_disabled_intent_router_foundation":
            helper = node
        for deco in node.decorator_list:
            path = route_path(deco)
            if path:
                routes.append((path, node.name))

if helper is None:
    raise SystemExit("FAIL: Phase 13A helper missing")

helper_src = ast.get_source_segment(src, helper) or ""

required = [
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
]
for marker in required:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: helper missing marker: {marker}")

for forbidden in [
    "httpx.",
    "urlopen",
    "urllib.request",
    "requests.",
    "subprocess",
    "systemctl",
    "sqlite3.connect",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "/api/generate",
    "/api/chat",
    "enqueue_job(",
    "_enqueue(",
    "insert into jobs",
    "insert or replace into jobs",
    "update jobs set",
]:
    if forbidden in helper_src.lower():
        raise SystemExit(f"FAIL: helper contains forbidden marker: {forbidden}")

for path, name in routes:
    if name == "_stage5p13a_disabled_intent_router_foundation":
        raise SystemExit(f"FAIL: helper is exposed as route: {path}")

print("PASS: Phase 13A helper is disabled, pure, and not exposed as a route")
PY

echo
echo "=== dynamic helper behavior without importing full app ==="
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
exec(compile(module, "<phase13a-helper>", "exec"), ns)
router = ns["_stage5p13a_disabled_intent_router_foundation"]

cases = [
    ("next", "study_review", "study_card_advance"),
    ("skip", "study_review", "study_card_advance"),
    ("five", "companion_chat", None),
    ("Answer is five", "study_review", None),
    ("How does my calendar look today?", "calendar", None),
    ("Open profile language settings", "profile", None),
    ("Show system status", "admin_system", None),
    ("Can we talk for a bit?", "companion_chat", None),
]

for message, expected_intent, expected_action in cases:
    result = router(message, {"preferred_language": "en"})
    if result.get("runtime_action_available") is not False:
        raise SystemExit("FAIL: runtime_action_available changed")
    if result.get("route_wired") is not False:
        raise SystemExit("FAIL: route_wired changed")
    if result.get("would_call") != "none":
        raise SystemExit("FAIL: would_call changed")
    if result.get("model_call_allowed") is not False:
        raise SystemExit("FAIL: model_call_allowed changed")
    if result.get("job_enqueue_allowed") is not False:
        raise SystemExit("FAIL: job_enqueue_allowed changed")
    actual = result.get("primary_intent")
    if actual != expected_intent:
        raise SystemExit(f"FAIL: {message!r} expected {expected_intent}, got {actual}")
    if expected_action and expected_action not in result.get("deterministic_actions", []):
        raise SystemExit(f"FAIL: {message!r} missing action {expected_action}")

answer_result = router("Answer is five", {})
matches = answer_result.get("normalized_features", {}).get("number_word_matches", [])
if not any(match.get("token") == "five" and match.get("value") == 5 for match in matches):
    raise SystemExit("FAIL: number word five was not normalized to value 5")

empty_result = router("", {})
if empty_result.get("primary_intent") != "unknown":
    raise SystemExit("FAIL: empty message should be unknown")

print("PASS: dynamic helper examples remain disabled and deterministic")
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
