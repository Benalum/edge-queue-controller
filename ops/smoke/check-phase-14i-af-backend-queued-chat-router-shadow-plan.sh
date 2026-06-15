#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-af-backend-queued-chat-router-shadow-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
EDGE_APP="edge_controller.py"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AF backend queued-chat router shadow plan ==="

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
echo "=== current behavior still unchanged ==="
python3 - <<'PY'
from pathlib import Path

front = Path("frontend/study-ui/app.js").read_text()
edge = Path("edge_controller.py").read_text()

required_front = [
    'url: `${base}/chat/queued`,',
    'body: { message: prompt, requested_model: "gemma4:e4b" }',
    'function studyUiLegacyJobsFallbackEnabled()',
]
missing_front = [item for item in required_front if item not in front]
if missing_front:
    raise SystemExit(f"FAIL: missing frontend current behavior markers: {missing_front}")

required_edge = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
    '_s5f19_create_real_user_queued_chat_job',
]
missing_edge = [item for item in required_edge if item not in edge]
if missing_edge:
    raise SystemExit(f"FAIL: missing backend current behavior markers: {missing_edge}")

print("PASS: current fixed requested_model queued-chat behavior remains unchanged")
PY

echo
echo "=== pure router helper still available ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _stage5p13a_disabled_intent_router_foundation(",
    "does not call a model",
    "does not enqueue jobs",
    "recommended_model_tier",
    "primary_intent",
    "confidence",
    "deterministic_actions",
    "number_word_matches",
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_tool_call": True',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing pure router helper markers: {missing}")

print("PASS: pure deterministic router helper remains available")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-af-backend-queued-chat-router-shadow-plan.md").read_text()

required = [
    "This phase does not change runtime behavior.",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED=0",
    "no queued-chat router shadow decision is computed",
    "Router shadow result must not control live model choice yet.",
    "Do not enable live router model selection in this phase.",
    "Do not remove frontend `requested_model` in this phase.",
    "Do not use admin preview HTTP routes internally.",
    "Do not depend on `/api/router/dry-run` internally.",
    "Job 23 is not mutated.",
    "Phase 14I-AG should implement only the disabled-by-default backend env helper",
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
echo "=== done: Phase 14I-AF backend queued-chat router shadow plan smoke complete ==="
