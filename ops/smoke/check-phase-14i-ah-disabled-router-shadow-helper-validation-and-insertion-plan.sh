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
echo "=== helper exists but is not wired ==="
python3 - <<'PY'
from pathlib import Path

edge = Path("edge_controller.py").read_text()

required = [
    "def _phase14iag_queued_chat_router_shadow_enabled() -> bool:",
    "def _phase14iag_queued_chat_router_shadow_decision(guard_payload: dict | None) -> dict:",
    'return _phase14ik_env_bool("EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED", False)',
    "queued_chat_router_shadow_disabled",
]
missing = [item for item in required if item not in edge]
if missing:
    raise SystemExit(f"FAIL: missing helper markers: {missing}")

route_start = edge.find('@app.post("/api/chat/queued")')
if route_start < 0:
    raise SystemExit("FAIL: queued-chat route not found")

next_route = edge.find("\n@app.", route_start + 1)
route_block = edge[route_start:] if next_route < 0 else edge[route_start:next_route]

if "_phase14iag_queued_chat_router_shadow_decision" in route_block:
    raise SystemExit("FAIL: helper unexpectedly wired into queued-chat route")

route_required = [
    "_s5f17_reject_client_provided_user_id(guard_payload)",
    "_s5f19_create_real_user_queued_chat_job(",
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
]
missing_route = [item for item in route_required if item not in route_block]
if missing_route:
    raise SystemExit(f"FAIL: missing route insertion markers: {missing_route}")

print("PASS: helper exists, route insertion markers exist, helper not wired yet")
PY

echo
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
