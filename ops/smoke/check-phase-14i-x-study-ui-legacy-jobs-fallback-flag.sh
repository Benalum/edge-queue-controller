#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-x-study-ui-legacy-jobs-fallback-flag"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-X Study UI legacy jobs fallback flag ==="

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
echo "=== frontend helper verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG",
    "function studyUiLegacyJobsFallbackEnabled()",
    "window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED",
    "Object.prototype.hasOwnProperty.call(window, \"STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED\")",
    "if (value === false || value === 0) return false;",
    "/^(false|0|off|no)$/i.test(value.trim())",
    "return true;",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing frontend helper markers: {missing}")

if text.count("function studyUiLegacyJobsFallbackEnabled()") != 1:
    raise SystemExit("FAIL: expected exactly one studyUiLegacyJobsFallbackEnabled helper")

print("PASS: frontend default-enabled fallback helper verified")
PY2

echo
echo "=== guarded legacy jobs fallback verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "url: `${base}/chat/queued`,",
    "body: { message: prompt, requested_model: \"gemma4:e4b\" }",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "paths.push(`${base}/jobs/${jobId}`);",
    "paths.push(`${base}/job/${jobId}`);",
    "if (studyUiLegacyJobsFallbackEnabled())",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing guarded fallback markers: {missing}")

if text.count("if (studyUiLegacyJobsFallbackEnabled())") != 2:
    raise SystemExit(f"FAIL: expected exactly two helper guards, got {text.count('if (studyUiLegacyJobsFallbackEnabled())')}")

submit_primary = text.index("url: `${base}/chat/queued`,")
submit_legacy = text.index("url: `${base}/jobs`,")
poll_primary = text.index("`${base}/chat/queued/${encodeURIComponent(jobId)}`")
poll_legacy = text.index("paths.push(`${base}/jobs/${jobId}`);")

if submit_primary > submit_legacy:
    raise SystemExit("FAIL: queued-chat submit must remain before legacy jobs submit fallback")
if poll_primary > poll_legacy:
    raise SystemExit("FAIL: queued-chat poll must remain before legacy jobs poll fallback")

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

print("PASS: queued-chat preferred and legacy jobs fallback guarded/default-preserved")
PY2

echo
echo "=== backend route preservation verification ==="
python3 - <<'PY2'
from pathlib import Path

edge = Path("edge_controller.py").read_text()

required = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE",
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

print("PASS: backend direct /jobs routes preserved and not gated")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-x-study-ui-legacy-jobs-fallback-flag.md").read_text()

required = [
    "Phase 14I-X implements the Phase 14I-W plan",
    "`studyUiLegacyJobsFallbackEnabled()`",
    "`window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`",
    "`PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG`",
    "the helper returns enabled by default",
    "legacy local jobs submit fallback remains available by default",
    "legacy local jobs poll fallback remains available by default",
    "Direct backend routes remain enabled",
    "This phase does not change backend route gates.",
    "Job 23 is not mutated.",
    "Phase 14I-Y may perform a static validation plan",
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
echo "=== done: Phase 14I-X fallback flag smoke complete ==="
