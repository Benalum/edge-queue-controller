#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ae-router-dry-run-preview-surface-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
EDGE_APP="edge_controller.py"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AE router dry-run and preview surface inspection ==="

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
echo "=== pure router helper marker verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _stage5p13a_disabled_intent_router_foundation(",
    "This helper is intentionally not wired to live request flow.",
    "network calls",
    "does not call a model",
    "does not enqueue jobs",
    "does not",
    "recommended_model_tier",
    "primary_intent",
    "confidence",
    "deterministic_actions",
    "number_word_matches",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing pure router helper markers: {missing}")

print("PASS: pure deterministic router helper markers verified")
PY

echo
echo "=== dry-run and admin preview marker verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/router/dry-run")',
    '@app.post("/system/router/dry-run")',
    "async def stage6f_universal_intent_router_dry_run",
    "return _stage6f_router_response(body)",
    '@app.post("/admin/intent-router-preview")',
    "async def admin_intent_router_preview",
    "preview = _stage5p13a_disabled_intent_router_foundation(message, profile)",
    '"no_model_invocation": True',
    '"no_queue_write": True',
    '"no_tool_call": True',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing router dry-run/admin preview markers: {missing}")

print("PASS: dry-run and admin preview markers verified")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ae-router-dry-run-preview-surface-inspection.md").read_text()

required = [
    "The safest current reusable helper is:",
    "_stage5p13a_disabled_intent_router_foundation(message, profile)",
    "future queued-chat shadow routing should reuse the pure helper directly",
    "queued-chat internal shadow routing should not depend on HTTP routes",
    "queued-chat should not depend on an admin-only route",
    "Inspection found no obvious model-call, external HTTP, SQL mutation, or queue mutation markers",
    "Keep live queued-chat model behavior unchanged.",
    "Do not use the shadow decision to select the live model yet.",
    "No model calls are made by this documentation phase.",
    "Job 23 is not mutated.",
    "Phase 14I-AF should create a disabled-by-default backend queued-chat router shadow plan.",
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
echo "=== done: Phase 14I-AE router dry-run and preview surface inspection smoke complete ==="
