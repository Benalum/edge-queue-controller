#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ad-study-ui-queued-chat-router-integration-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"
EDGE_APP="edge_controller.py"

echo "=== Phase 14I-AD Study UI queued-chat router integration plan ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$STUDY_APP"
test -f "$EDGE_APP"
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
echo "=== current fixed model behavior still unchanged ==="
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
]
missing_edge = [item for item in required_edge if item not in edge]
if missing_edge:
    raise SystemExit(f"FAIL: missing backend current behavior markers: {missing_edge}")

print("PASS: current fixed requested_model behavior remains unchanged")
PY

echo
echo "=== existing router surface markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/router/dry-run")',
    '@app.post("/system/router/dry-run")',
    '@app.post("/admin/intent-router-preview")',
    'async def stage6f_universal_intent_router_dry_run',
    'async def admin_intent_router_preview',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing router surface markers: {missing}")

print("PASS: existing router/dry-run/preview markers found")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ad-study-ui-queued-chat-router-integration-plan.md").read_text()

required = [
    "This phase does not change runtime behavior.",
    "Study UI companion queued-chat traffic is not yet using the router for model selection.",
    "Stage AD-1: Shadow-read only",
    "Stage AD-2: Frontend omission flag",
    "window.STUDY_UI_QUEUED_CHAT_ROUTER_SELECTION_ENABLED = true",
    "Stage AD-3: Backend router selection flag",
    "EDGE_QUEUED_CHAT_ROUTER_MODEL_SELECTION_ENABLED=0",
    "Do not remove `requested_model` from the frontend yet.",
    "Do not enable backend router model selection yet.",
    "Do not call live model endpoints in smoke tests.",
    "Phase 14I-AE should perform a read-only inspection",
    "Job 23 is not mutated.",
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
echo "=== done: Phase 14I-AD router integration plan smoke complete ==="
