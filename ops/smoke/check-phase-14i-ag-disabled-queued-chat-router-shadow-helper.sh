#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ag-disabled-queued-chat-router-shadow-helper"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
EDGE_APP="edge_controller.py"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AG disabled queued-chat router shadow helper ==="

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
echo "=== helper implementation markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _phase14iag_queued_chat_router_shadow_enabled() -> bool:",
    'return _phase14ik_env_bool("EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED", False)',
    "def _phase14iag_queued_chat_router_shadow_decision(guard_payload: dict | None) -> dict:",
    "queued_chat_router_shadow_disabled",
    "_stage5p13a_disabled_intent_router_foundation(message, profile)",
    '"live_model_selection_changed": False',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"browser_exposure_allowed": False',
    '"recommended_model_tier": preview.get("recommended_model_tier")',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing helper implementation markers: {missing}")

print("PASS: helper implementation markers verified")
PY

echo
echo "=== route behavior unchanged verification ==="
python3 - <<'PY'
from pathlib import Path

edge = Path("edge_controller.py").read_text()
front = Path("frontend/study-ui/app.js").read_text()

route_start = edge.find('@app.post("/api/chat/queued")')
if route_start < 0:
    raise SystemExit("FAIL: queued-chat route not found")
next_route = edge.find("\n@app.", route_start + 1)
route_block = edge[route_start:] if next_route < 0 else edge[route_start:next_route]

if "_phase14iag_queued_chat_router_shadow_decision" in route_block:
    raise SystemExit("FAIL: Phase 14I-AG helper is unexpectedly wired into /api/chat/queued")

required_edge = [
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
    "_s5f19_create_real_user_queued_chat_job",
]
missing_edge = [item for item in required_edge if item not in route_block]
if missing_edge:
    raise SystemExit(f"FAIL: missing current queued-chat route markers: {missing_edge}")

required_front = [
    'url: `${base}/chat/queued`,',
    'body: { message: prompt, requested_model: "gemma4:e4b" }',
]
missing_front = [item for item in required_front if item not in front]
if missing_front:
    raise SystemExit(f"FAIL: missing frontend fixed requested_model markers: {missing_front}")

print("PASS: queued-chat route and frontend live behavior remain unchanged")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ag-disabled-queued-chat-router-shadow-helper.md").read_text()

required = [
    "This phase preserves live behavior.",
    "This phase does not wire the helper into `/api/chat/queued`.",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "Default behavior:",
    "returns disabled metadata",
    "Router shadow results do not control live model choice.",
    "Job 23 is not mutated.",
    "Phase 14I-AH should statically validate the disabled helper behavior",
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
echo "=== done: Phase 14I-AG disabled queued-chat router shadow helper smoke complete ==="
