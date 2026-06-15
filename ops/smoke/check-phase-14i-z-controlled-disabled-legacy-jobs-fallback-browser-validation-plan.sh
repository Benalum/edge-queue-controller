#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-z-controlled-disabled-legacy-jobs-fallback-browser-validation-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-Z controlled disabled legacy jobs fallback browser validation plan ==="

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
echo "=== frontend disabled fallback readiness verification ==="
python3 - <<'PY'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "function studyUiLegacyJobsFallbackEnabled()",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED",
    "if (value === false || value === 0) return false;",
    "/^(false|0|off|no)$/i.test(value.trim())",
    "return true;",
    "if (studyUiLegacyJobsFallbackEnabled())",
    "url: `${base}/chat/queued`,",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "url: `${base}/jobs`,",
    "paths.push(`${base}/jobs/${jobId}`);",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend validation markers: {missing}")

if text.count("function studyUiLegacyJobsFallbackEnabled()") != 1:
    raise SystemExit("FAIL: expected exactly one fallback helper")
if text.count("if (studyUiLegacyJobsFallbackEnabled())") != 2:
    raise SystemExit("FAIL: expected exactly two fallback guards")

print("PASS: frontend disabled fallback readiness markers verified")
PY

echo
echo "=== backend route preservation verification ==="
python3 - <<'PY'
from pathlib import Path

edge = Path("edge_controller.py").read_text()

required = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
]
missing = [item for item in required if item not in edge]
if missing:
    raise SystemExit(f"FAIL: missing backend route markers: {missing}")

print("PASS: backend direct /jobs and queued-chat routes remain present")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-z-controlled-disabled-legacy-jobs-fallback-browser-validation-plan.md").read_text()

required = [
    "Phase 14I-Z records the safe plan",
    "This phase does not perform the browser validation.",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false",
    "legacy `/jobs` submit fallback is not used by the frontend",
    "legacy `/jobs/{job_id}` poll fallback is not used by the frontend",
    "Do not run this validation through smoke scripts.",
    "Do not automate live job creation in smoke scripts.",
    "Do not call model endpoints in smoke scripts.",
    "Do not mutate job 23.",
    "Backend direct local jobs routes stay enabled",
    "A later phase may perform the controlled browser-observed validation manually.",
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
echo "=== done: Phase 14I-Z browser validation plan smoke complete ==="
