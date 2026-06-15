#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-r-direct-local-jobs-usage-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-R direct local jobs usage inspection ==="

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
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== active Study UI direct /jobs caller verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "async function pollJob(jobId, pollUrl = \"\")",
    "async function sendCompanionToApi(message)",
    "`${base}/jobs/${jobId}`",
    "url: `${base}/jobs`,",
    "COMPANION_JOB_FIRST_V1",
    "job_type: \"ollama_chat\"",
    "requested_model: \"gemma4:e4b\"",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Study UI direct /jobs caller markers: {missing}")

if text.count("`${base}/jobs/${jobId}`") != 1:
    raise SystemExit("FAIL: expected exactly one Study UI direct /jobs poll fallback")

if text.count("url: `${base}/jobs`,") != 1:
    raise SystemExit("FAIL: expected exactly one Study UI direct /jobs submit caller")

print("PASS: active Study UI direct /jobs submit/poll caller markers verified")
PY2

echo
echo "=== route definition counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    '@app.post("/jobs")': 1,
    '@app.get("/jobs")': 1,
    '@app.post("/public/jobs")': 1,
    '@app.get("/public/jobs/{job_id}")': 1,
    '@app.get("/public/jobs")': 1,
    '@app.post("/api/chat/queued")': 1,
    '@app.get("/api/chat/queued/{job_id}")': 1,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

if bad:
    raise SystemExit(f"FAIL: unexpected route definition counts: {bad}")

print("PASS: route definition counts match Phase 14I-R baseline")
PY2

echo
echo "=== helper and local create counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    "_phase14ik_legacy_local_jobs_routes_enabled(": 4,
    "_phase14ik_legacy_companion_local_job_create_enabled(": 2,
    "_phase14ik_legacy_local_queue_status_enabled(": 2,
    "_phase14ik_legacy_local_jobs_admin_archive_enabled(": 1,
    "_public_create_ollama_job(": 3,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

if bad:
    raise SystemExit(f"FAIL: unexpected helper/create counts: {bad}")

print("PASS: helper and local create counts match Phase 14I-R inspection baseline")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-r-direct-local-jobs-usage-inspection.md").read_text()

required = [
    "Phase 14I-R records repo usage of the direct local Edge `jobs` routes",
    "The focused active-code scan found one real active caller file:",
    "`frontend/study-ui/app.js`",
    "`` `${base}/jobs/${jobId}` ``",
    "`` `${base}/jobs` ``",
    "Therefore, `POST /jobs` and `GET /jobs` should not be gated yet.",
    "Job 23 is not mutated.",
    "Phase 14I-S should inspect and document the Study UI companion queue path migration plan.",
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
echo "=== done: Phase 14I-R usage inspection smoke complete ==="
