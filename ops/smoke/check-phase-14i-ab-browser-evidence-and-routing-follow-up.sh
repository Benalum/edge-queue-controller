#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-ab-browser-evidence-and-routing-follow-up"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AB browser evidence and routing follow-up ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$STUDY_APP"
echo "PASS: required docs/smoke/frontend files exist"

echo
echo "=== compile and frontend syntax ==="
python3 -m py_compile edge_controller.py
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
    'window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend routing markers: {missing}")

print("PASS: Study UI fixed requested_model and guarded fallback markers verified")
PY

echo
echo "=== backend queued-chat route verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
    '@app.post("/jobs")',
    '@app.get("/jobs")',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing backend queued-chat or direct jobs markers: {missing}")

print("PASS: backend queued-chat and direct jobs route markers verified")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ab-browser-evidence-and-routing-follow-up.md").read_text()

required = [
    "disabled frontend legacy `/jobs` fallback appears to work",
    "Study UI currently requests `gemma4:e4b` directly",
    "this path does not yet prove dynamic router or decision-maker selection",
    "The browser response took longer than expected",
    "Do not gate backend direct `/jobs` yet.",
    "Phase 14I-AC should inspect the model router and decision-maker surfaces",
    "whether frontend should omit `requested_model`",
    "how to avoid slowing simple prompts with a heavier model",
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
echo "=== done: Phase 14I-AB browser evidence and routing follow-up smoke complete ==="
