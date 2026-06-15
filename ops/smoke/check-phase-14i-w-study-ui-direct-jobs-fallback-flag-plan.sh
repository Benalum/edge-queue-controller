#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-w-study-ui-direct-jobs-fallback-flag-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-W Study UI direct jobs fallback flag plan ==="

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
echo "=== Study UI current fallback state verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER",
    "url: `${base}/chat/queued`,",
    "body: { message: prompt, requested_model: \"gemma4:e4b\" }",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "`${base}/jobs/${jobId}`",
    "`${base}/job/${jobId}`",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Study UI adapter/fallback markers: {missing}")

if text.index("url: `${base}/chat/queued`,") > text.index("url: `${base}/jobs`,"):
    raise SystemExit("FAIL: queued-chat submit must remain before legacy /jobs submit fallback")
if text.index("`${base}/chat/queued/${encodeURIComponent(jobId)}`") > text.index("`${base}/jobs/${jobId}`"):
    raise SystemExit("FAIL: queued-chat poll must remain before legacy /jobs poll fallback")

expected_counts = {
    "/chat/queued": 2,
    "/jobs": 2,
    "/public/jobs": 0,
    "PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER": 1,
}
bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}
if bad:
    raise SystemExit(f"FAIL: unexpected Study UI marker counts: {bad}")

print("PASS: Study UI queued-chat preferred with direct /jobs fallback baseline verified")
PY2

echo
echo "=== frontend flag patch-point verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "function getApiBase()",
    "typeof API_BASE",
    "localStorage",
    "async function pollJob(jobId, pollUrl = \"\")",
    "async function sendCompanionToApi(message)",
    "const paths = [",
    "const attempts = [",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend flag patch-point markers: {missing}")

if "studyUiLegacyJobsFallbackEnabled" in text:
    raise SystemExit("FAIL: frontend helper already implemented; update Phase 14I-W plan/smoke")

if "STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED" in text:
    raise SystemExit("FAIL: frontend global override already implemented; update Phase 14I-W plan/smoke")

print("PASS: frontend patch points are ready and fallback flag is not implemented yet")
PY2

echo
echo "=== backend direct jobs gate readiness verification ==="
python3 - <<'PY2'
from pathlib import Path

edge = Path("edge_controller.py").read_text()
front = Path("frontend/study-ui/app.js").read_text()

required_edge = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE",
    "_phase14ik_legacy_local_jobs_routes_enabled(",
]
missing_edge = [item for item in required_edge if item not in edge]
if missing_edge:
    raise SystemExit(f"FAIL: missing backend route/gate markers: {missing_edge}")

if 'url: `${base}/jobs`,' not in front or '`${base}/jobs/${jobId}`' not in front:
    raise SystemExit("FAIL: expected Study UI direct /jobs fallback references missing")

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

print("PASS: backend direct /jobs routes remain enabled and are not ready to gate")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-w-study-ui-direct-jobs-fallback-flag-plan.md").read_text()

required = [
    "Phase 14I-W records the safe plan",
    "`studyUiLegacyJobsFallbackEnabled()`",
    "`window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`",
    "enabled by default",
    "preserve direct `/jobs` submit fallback",
    "preserve direct `/jobs` poll fallback",
    "backend direct `POST /jobs` and `GET /jobs` are still not ready to gate",
    "the next implementation should only flag the frontend fallback",
    "Job 23 is not mutated.",
    "Phase 14I-X may implement the default-enabled frontend helper.",
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
echo "=== done: Phase 14I-W fallback flag plan smoke complete ==="
