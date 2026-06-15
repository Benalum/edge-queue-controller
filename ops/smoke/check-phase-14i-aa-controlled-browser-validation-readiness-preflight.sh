#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-aa-controlled-browser-validation-readiness-preflight"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-AA controlled browser validation readiness preflight ==="

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
echo "=== frontend fallback flag readiness ==="
python3 - <<'PY'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "function studyUiLegacyJobsFallbackEnabled()",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED",
    "if (value === false || value === 0) return false;",
    "/^(false|0|off|no)$/i.test(value.trim())",
    "url: `${base}/chat/queued`,",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "url: `${base}/jobs`,",
    "paths.push(`${base}/jobs/${jobId}`);",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend fallback readiness markers: {missing}")

print("PASS: frontend fallback flag readiness markers verified")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-aa-controlled-browser-validation-readiness-preflight.md").read_text()

required = [
    "Phase 14I-AA prepares the exact browser validation checklist",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false",
    "Say hello in one short sentence.",
    "frontend should not submit this request to direct `/jobs`",
    "frontend should not poll direct `/jobs/{job_id}`",
    "frontend should not poll direct `/job/{job_id}`",
    "Do not paste auth tokens.",
    "Do not paste cookies.",
    "Even if browser validation passes, backend direct `/jobs` should not be gated in the same step.",
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
echo "=== done: Phase 14I-AA readiness preflight smoke complete ==="
