#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ac-router-decision-maker-surface-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"
EDGE_APP="edge_controller.py"

echo "=== Phase 14I-AC router and decision-maker surface inspection ==="

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
echo "=== frontend fixed requested model verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    'url: `${base}/chat/queued`,',
    'body: { message: prompt, requested_model: "gemma4:e4b" }',
    'url: `${base}/jobs`,',
    'body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" }',
    'function studyUiLegacyJobsFallbackEnabled()',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend fixed model markers: {missing}")

print("PASS: Study UI still uses fixed requested_model markers")
PY

echo
echo "=== queued-chat route routing marker verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

start = text.find('@app.post("/api/chat/queued")')
if start < 0:
    raise SystemExit("FAIL: queued-chat route not found")

next_route = text.find("\n@app.", start + 1)
block = text[start:] if next_route < 0 else text[start:next_route]

required = [
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
    '_s5f19_create_real_user_queued_chat_job',
]
missing = [item for item in required if item not in block]
if missing:
    raise SystemExit(f"FAIL: missing queued-chat route pass-through markers: {missing}")

for forbidden in ["router", "decision", "intent", "tier", "classifier"]:
    if forbidden in block.lower():
        raise SystemExit(f"FAIL: queued-chat route unexpectedly contains dynamic routing marker: {forbidden}")

print("PASS: queued-chat route appears to pass requested_model through without dynamic routing markers")
PY

echo
echo "=== router surface marker verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    'async def stage6f_universal_intent_router_dry_run',
    'def _stage5p13a_disabled_intent_router_foundation',
    'async def admin_intent_router_preview',
    '@app.post("/api/router/dry-run")',
    '@app.post("/system/router/dry-run")',
    '@app.post("/admin/intent-router-preview")',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing existing router surface markers: {missing}")

print("PASS: existing router and decision-maker surface markers found")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ac-router-decision-maker-surface-inspection.md").read_text()

required = [
    "Study UI currently requests `gemma4:e4b` directly.",
    "The frontend is not delegating model choice yet.",
    "`/api/chat/queued` appears to pass `requested_model` through.",
    "`/api/chat/queued` does not appear to run dynamic routing inside that route.",
    "router and intent surfaces exist",
    "integration should be planned as a separate phase",
    "Simple prompts may be slow because they are still routed to a heavier fixed model.",
    "Should the frontend omit `requested_model`",
    "Should router decisions be logged before being trusted for live routing?",
    "Job 23 is not mutated.",
    "Phase 14I-AD should create a router integration plan",
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
echo "=== done: Phase 14I-AC router and decision-maker surface inspection smoke complete ==="
