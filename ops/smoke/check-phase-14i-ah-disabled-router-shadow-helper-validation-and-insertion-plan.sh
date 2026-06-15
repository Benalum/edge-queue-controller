#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ah-disabled-router-shadow-helper-validation-and-insertion-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
EDGE_APP="edge_controller.py"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AH disabled router shadow helper validation and insertion plan ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$EDGE_APP"
test -f "$STUDY_APP"
echo "PASS: required docs/smoke/source files exist"

echo
echo "=== compile and frontend syntax ==="
python3 -m py_compile "$EDGE_APP"
if command -v node >/dev/null 2>&1; then
  node --check "$STUDY_APP"
else
  echo "WARN: node not found; skipped frontend syntax check"
fi
echo "PASS: compile/frontend syntax check complete"

echo
echo
echo "=== helper wiring compatibility verification ==="
python3 - <<'INNERPY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

route_start = text.index('@app.post("/api/chat/queued")')
route_end = text.index('@app.get("/api/chat/queued/{job_id}")', route_start)
route = text[route_start:route_end]

call = "_phase14iag_queued_chat_router_shadow_decision(guard_payload)"
ai_start = "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_START"
ai_end = "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_END"

required_global = [
    "def _phase14iag_queued_chat_router_shadow_enabled",
    "def _phase14iag_queued_chat_router_shadow_decision",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "live_model_selection_changed",
    "model_call_allowed",
    "job_enqueue_allowed",
    "browser_exposure_allowed",
]

for marker in required_global:
    if marker not in text:
        raise SystemExit(f"FAIL: missing global shadow safety marker: {marker}")

if call in route or ai_start in route or ai_end in route:
    required_route = [
        ai_start,
        call,
        ai_end,
        "payload=guard_payload",
        'requested_model=request.requested_model or "synthetic"',
    ]
    for marker in required_route:
        if marker not in route:
            raise SystemExit(f"FAIL: missing post-AI route marker: {marker}")

    if route.count(call) != 1:
        raise SystemExit(f"FAIL: expected exactly one queued-chat shadow call, found {route.count(call)}")

    call_line = [line.strip() for line in route.splitlines() if call in line]
    if call_line != [call]:
        raise SystemExit("FAIL: shadow helper return value should be discarded")

    call_idx = route.index(call)
    creation_idx = route.index("if _s5f19_real_user_creation_helper_enabled():")
    if call_idx >= creation_idx:
        raise SystemExit("FAIL: shadow call appears after real-user job creation gate")

    if route.rfind("auth_user =", 0, call_idx) == -1:
        raise SystemExit("FAIL: shadow call appears before auth resolution")

    forbidden_response_keys = [
        '"router_shadow"',
        "'router_shadow'",
        '"router_decision"',
        "'router_decision'",
        '"shadow_decision"',
        "'shadow_decision'",
    ]
    for key in forbidden_response_keys:
        if key in route:
            raise SystemExit(f"FAIL: queued-chat route exposes forbidden router key: {key}")

    print("PASS: post-AI shadow-only queued-chat wiring is compatible")
else:
    print("PASS: pre-AI helper remains unwired")
INNERPY
echo "PASS: helper exists and queued-chat wiring state is compatible"
echo "=== current frontend behavior unchanged ==="
python3 - <<'PY'
from pathlib import Path

front = Path("frontend/study-ui/app.js").read_text()

required = [
    'url: `${base}/chat/queued`,',
    'body: { message: prompt, requested_model: "gemma4:e4b" }',
    'function studyUiLegacyJobsFallbackEnabled()',
]
missing = [item for item in required if item not in front]
if missing:
    raise SystemExit(f"FAIL: missing frontend current behavior markers: {missing}")

print("PASS: current Study UI fixed requested_model behavior remains unchanged")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ah-disabled-router-shadow-helper-validation-and-insertion-plan.md").read_text()

required = [
    "This phase does not wire the helper into `/api/chat/queued`.",
    "The helper is not currently wired into:",
    "Future wiring should be inserted in `/api/chat/queued` after:",
    "_s5f17_reject_client_provided_user_id(guard_payload)",
    "_s5f19_create_real_user_queued_chat_job(...)",
    "Do not use this variable to select the live model yet.",
    "Do not enable router shadow by default.",
    "Job 23 is not mutated.",
    "Phase 14I-AI should wire the helper into `/api/chat/queued` behind the existing default-off backend flag.",
]
missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|curl[[:space:]].*/queue/summary|curl[[:space:]].*/system/status|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
model_danger="$(
  grep -RInE 'curl.*(/api/generate|/api/chat|/admin/model-warmup)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ] || [ -n "$model_danger" ]; then
  [ -n "$danger" ] && echo "$danger"
  [ -n "$model_danger" ] && echo "$model_danger"
  echo "FAIL: smoke script contains mutation, model execution, or live queue dump pattern"
  exit 1
fi
echo "PASS: read-only/privacy guard passed"

echo
echo "=== done: Phase 14I-AH disabled router shadow helper validation and insertion plan smoke complete ==="
