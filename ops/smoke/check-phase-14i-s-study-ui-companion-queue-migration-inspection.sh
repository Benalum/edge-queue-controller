#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-s-study-ui-companion-queue-migration-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-S Study UI companion queue migration inspection ==="

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
echo "=== Study UI current direct jobs flow verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "function getApiBase()",
    "async function pollJob(jobId, pollUrl = \"\")",
    "function buildCompanionPrompt(message)",
    "async function sendCompanionToApi(message)",
    "`${base}/jobs/${jobId}`",
    "`${base}/job/${jobId}`",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
    "COMPANION_JOB_FIRST_V1",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Study UI queue-flow markers: {missing}")

has_phase14iu_adapter = "PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER" in text

if "/api/chat/queued" in text and not has_phase14iu_adapter:
    raise SystemExit("FAIL: Study UI references /api/chat/queued without Phase 14I-U adapter marker")

if text.count("/jobs") != 2:
    raise SystemExit(f"FAIL: expected Study UI legacy /jobs fallback count 2, got {text.count('/jobs')}")

if has_phase14iu_adapter:
    required_u = [
        "url: `${base}/chat/queued`,",
        "body: { message: prompt, requested_model: \"gemma4:e4b\" }",
        "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
        "url: `${base}/jobs`,",
        "`${base}/jobs/${jobId}`",
    ]
    missing_u = [item for item in required_u if item not in text]
    if missing_u:
        raise SystemExit(f"FAIL: Phase 14I-U adapter marker present but required fallback markers missing: {missing_u}")
    print("PASS: Study UI direct /jobs fallback preserved with expected Phase 14I-U queued-chat adapter")
else:
    print("PASS: Study UI direct /jobs companion flow matches Phase 14I-S inspection baseline")
PY2

echo
echo "=== backend queued chat route verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "stage_5f19_real_user_route",
    "stage_5f20_real_user_status_route",
    '"job_id": queued.job_id',
    '"status": queued.status',
    '"chat_id": queued.chat_id',
    '"user_message_id": queued.user_message_id',
    '"payload_json": queued.payload_json',
    "FROM app_jobs",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing backend queued chat markers: {missing}")

if "_public_create_ollama_job(" not in text:
    raise SystemExit("FAIL: expected legacy local jobs helper still present during migration inspection")

print("PASS: backend /api/chat/queued route markers match Phase 14I-S inspection baseline")
PY2

echo
echo "=== route and helper counts ==="
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
    "_phase14ik_legacy_local_jobs_routes_enabled(": 4,
    "_public_create_ollama_job(": 3,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

if bad:
    raise SystemExit(f"FAIL: unexpected route/helper counts: {bad}")

print("PASS: route/helper counts match Phase 14I-S baseline")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-s-study-ui-companion-queue-migration-inspection.md").read_text()

required = [
    "Phase 14I-S records the read-only inspection of the Study UI companion queue path.",
    "`frontend/study-ui/app.js`",
    "`` `${base}/jobs` ``",
    "`` `${base}/jobs/${jobId}` ``",
    "`/api/chat/queued`",
    "`POST /api/chat/queued`",
    "`GET /api/chat/queued/{job_id}`",
    "The migration should not be a blind route swap yet.",
    "Job 23 is not mutated.",
    "Phase 14I-T should document the frontend migration plan.",
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
echo "=== done: Phase 14I-S migration inspection smoke complete ==="
