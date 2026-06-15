#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-o-remaining-legacy-local-jobs-read-list-route-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-O remaining legacy local jobs read/list route inspection ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

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
echo "=== static route inventory ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_routes = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/public/jobs")',
    '@app.get("/public/jobs/{job_id}")',
    '@app.get("/public/jobs")',
    '@app.post("/public/companion/chat")',
    '@app.post("/api/companion/chat")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
]

missing = [route for route in expected_routes if text.count(route) != 1]
if missing:
    raise SystemExit(f"FAIL: missing or duplicate route markers: {missing}")

required_markers = [
    "PHASE_14I_N_LEGACY_PUBLIC_LOCAL_JOBS_CREATE_GATE_BEGIN",
    "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_BEGIN",
    "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE_BEGIN",
]
missing_markers = [marker for marker in required_markers if marker not in text]
if missing_markers:
    raise SystemExit(f"FAIL: missing prior gate markers: {missing_markers}")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

for forbidden in [
    "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE",
    "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE",
    "PHASE_14I_N_LEGACY_PUBLIC_LOCAL_JOBS_CREATE_GATE",
    "_phase14ik_legacy_local_jobs_routes_enabled",
    "_phase14ik_legacy_companion_local_job_create_enabled",
    "_phase14ik_legacy_local_queue_status_enabled",
]:
    if forbidden in api_block:
        raise SystemExit(f"FAIL: /api/chat/queued contains legacy local jobs marker/helper: {forbidden}")

print("PASS: route inventory and /api/chat/queued preservation verified")
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

print("PASS: helper and local create counts match Phase 14I-O/P inspection baseline")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-o-remaining-legacy-local-jobs-read-list-route-inspection.md").read_text()

required = [
    "Phase 14I-O records the static route-shape inspection after Phase 14I-N.",
    "`GET /public/jobs/{job_id}`",
    "`GET /public/jobs`",
    "`POST /api/chat/queued`",
    "`_public_create_ollama_job(` count is expected to be 3 after Phase 14I-N",
    "Job 23 is not mutated.",
    "Phase 14I-P can gate the remaining legacy local jobs read/list route family",
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
echo "=== done: Phase 14I-O inspection smoke complete ==="
