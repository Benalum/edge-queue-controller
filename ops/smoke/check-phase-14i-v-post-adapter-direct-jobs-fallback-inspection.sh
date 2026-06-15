#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-v-post-adapter-direct-jobs-fallback-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-V post-adapter direct jobs fallback inspection ==="

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
echo "=== Study UI adapter/fallback order verification ==="
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

submit_primary = text.index("url: `${base}/chat/queued`,")
submit_legacy = text.index("url: `${base}/jobs`,")
poll_primary = text.index("`${base}/chat/queued/${encodeURIComponent(jobId)}`")
poll_legacy = text.index("`${base}/jobs/${jobId}`")

if submit_primary > submit_legacy:
    raise SystemExit("FAIL: queued-chat submit must precede direct /jobs fallback")
if poll_primary > poll_legacy:
    raise SystemExit("FAIL: queued-chat poll must precede direct /jobs fallback")
if text.count("/chat/queued") != 2:
    raise SystemExit(f"FAIL: expected Study UI /chat/queued count 2, got {text.count('/chat/queued')}")
if text.count("/jobs") != 2:
    raise SystemExit(f"FAIL: expected Study UI direct /jobs fallback count 2, got {text.count('/jobs')}")
if "/public/jobs" in text:
    raise SystemExit("FAIL: Study UI must not reference /public/jobs")

print("PASS: Study UI adapter/fallback order and counts verified")
PY2

echo
echo "=== direct /jobs backend/fallback decision verification ==="
python3 - <<'PY2'
from pathlib import Path

edge = Path("edge_controller.py").read_text()
front = Path("frontend/study-ui/app.js").read_text()

required_edge = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
]
missing_edge = [item for item in required_edge if item not in edge]
if missing_edge:
    raise SystemExit(f"FAIL: missing required backend route markers: {missing_edge}")

required_front = [
    "url: `${base}/chat/queued`,",
    "url: `${base}/jobs`,",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "`${base}/jobs/${jobId}`",
]
missing_front = [item for item in required_front if item not in front]
if missing_front:
    raise SystemExit(f"FAIL: missing required frontend fallback decision markers: {missing_front}")

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

print("PASS: direct /jobs remains enabled because Study UI fallback still references it")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-v-post-adapter-direct-jobs-fallback-inspection.md").read_text()

required = [
    "Phase 14I-V records the post-adapter validation after Phase 14I-U.",
    "queued-chat submit is before legacy direct `/jobs` submit fallback",
    "queued-chat poll is before legacy direct `/jobs` poll fallback",
    "Study UI has exactly two `/chat/queued` references",
    "Study UI has exactly two direct `/jobs` fallback references",
    "Study UI has zero `/public/jobs` references",
    "direct `POST /jobs` and `GET /jobs` must remain enabled while Study UI fallback references exist",
    "direct `/jobs` is not ready to gate yet",
    "Job 23 is not mutated.",
    "Phase 14I-W may plan the next retirement step.",
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
echo "=== done: Phase 14I-V fallback inspection smoke complete ==="
