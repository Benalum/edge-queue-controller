#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-y-disabled-frontend-legacy-jobs-fallback-validation"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-Y disabled frontend legacy jobs fallback validation ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$STUDY_APP"
echo "PASS: required docs/smoke/frontend files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -10
git tag --points-at HEAD || true

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
echo "=== disabled fallback helper validation ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG",
    "function studyUiLegacyJobsFallbackEnabled()",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED",
    "if (value === false || value === 0) return false;",
    "/^(false|0|off|no)$/i.test(value.trim())",
    "return true;",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing disabled fallback helper markers: {missing}")

if text.count("function studyUiLegacyJobsFallbackEnabled()") != 1:
    raise SystemExit("FAIL: expected exactly one fallback helper")
if text.count("if (studyUiLegacyJobsFallbackEnabled())") != 2:
    raise SystemExit(f"FAIL: expected exactly two fallback guards, got {text.count('if (studyUiLegacyJobsFallbackEnabled())')}")

print("PASS: disabled fallback helper accepts expected disable values and defaults enabled")
PY2

echo
echo "=== guarded fallback block validation ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "url: `${base}/chat/queued`,",
    "body: { message: prompt, requested_model: \"gemma4:e4b\" }",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "paths.push(`${base}/jobs/${jobId}`);",
    "paths.push(`${base}/job/${jobId}`);",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing guarded fallback markers: {missing}")

queued_submit = text.index("url: `${base}/chat/queued`,")
legacy_submit = text.index("url: `${base}/jobs`,")
queued_poll = text.index("`${base}/chat/queued/${encodeURIComponent(jobId)}`")
legacy_poll = text.index("paths.push(`${base}/jobs/${jobId}`);")

if queued_submit > legacy_submit:
    raise SystemExit("FAIL: queued submit must remain before legacy jobs fallback")
if queued_poll > legacy_poll:
    raise SystemExit("FAIL: queued poll must remain before legacy jobs fallback")

expected_counts = {
    "/chat/queued": 2,
    "/jobs": 2,
    "/public/jobs": 0,
    "PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER": 1,
    "PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG": 1,
}
bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}
if bad:
    raise SystemExit(f"FAIL: unexpected Study UI marker counts: {bad}")

print("PASS: guarded fallback blocks and ordering verified")
PY2

echo
echo "=== backend route preservation validation ==="
python3 - <<'PY2'
from pathlib import Path

edge = Path("edge_controller.py").read_text()

required = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "_phase14ik_legacy_local_jobs_routes_enabled(",
]
missing = [item for item in required if item not in edge]
if missing:
    raise SystemExit(f"FAIL: missing backend route/gate markers: {missing}")

expected_counts = {
    '@app.post("/jobs")': 1,
    '@app.get("/jobs")': 1,
    '@app.post("/api/chat/queued")': 1,
    '@app.get("/api/chat/queued/{job_id}")': 1,
    "_phase14ik_legacy_local_jobs_routes_enabled(": 4,
    "_public_create_ollama_job(": 3,
}
bad = {}
for marker, expected in expected_counts.items():
    actual = edge.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}
if bad:
    raise SystemExit(f"FAIL: unexpected backend route/helper counts: {bad}")

print("PASS: backend direct /jobs routes remain enabled and unchanged")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-y-disabled-frontend-legacy-jobs-fallback-validation.md").read_text()

required = [
    "Phase 14I-Y records static proof",
    "`studyUiLegacyJobsFallbackEnabled()`",
    "`window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`",
    "`false`",
    "`0`",
    "`\"false\"`",
    "`\"0\"`",
    "`\"off\"`",
    "`\"no\"`",
    "The default remains enabled",
    "No live browser validation was performed in Phase 14I-Y.",
    "No job was created.",
    "No model call was made.",
    "backend `POST /jobs` and `GET /jobs` still remain enabled",
    "do not flip the frontend fallback flag off globally yet",
    "Job 23 is not mutated.",
    "Phase 14I-Z may plan a controlled browser-observed validation",
]
missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY2

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
echo "=== done: Phase 14I-Y disabled fallback validation smoke complete ==="
