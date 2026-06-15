#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-p-gate-public-legacy-local-jobs-read-list-routes"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
SMOKE_K="ops/smoke/check-phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers.sh"
SMOKE_L="ops/smoke/check-phase-14i-l-gate-legacy-local-queue-status.sh"
SMOKE_M="ops/smoke/check-phase-14i-m-gate-legacy-companion-local-job-creation.sh"
SMOKE_N="ops/smoke/check-phase-14i-n-gate-legacy-public-local-jobs-creation.sh"
SMOKE_O="ops/smoke/check-phase-14i-o-remaining-legacy-local-jobs-read-list-route-inspection.sh"

echo "=== Phase 14I-P gate public legacy local jobs read/list routes ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$SMOKE_K"
test -x "$SMOKE_K"
test -f "$SMOKE_L"
test -x "$SMOKE_L"
test -f "$SMOKE_M"
test -x "$SMOKE_M"
test -f "$SMOKE_N"
test -x "$SMOKE_N"
test -f "$SMOKE_O"
test -x "$SMOKE_O"
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
echo "=== static public read/list gate verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE_BEGIN",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE_END",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE_BEGIN",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE_END",
    "legacy_public_local_jobs_read_disabled",
    "legacy_public_local_jobs_list_disabled",
    "legacy_local_jobs_disabled_phase_14i_p",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing public read/list gate markers: {missing}")

read_route = '@app.get("/public/jobs/{job_id}")'
list_route = '@app.get("/public/jobs")'

if read_route not in text or list_route not in text:
    raise SystemExit("FAIL: missing public jobs read/list route decorators")

read_start = text.index(read_route)
read_next = text.find("\n@app.", read_start + 1)
read_block = text[read_start: read_next if read_next != -1 else len(text)]

list_start = text.index(list_route)
list_next = text.find("\n@app.", list_start + 1)
list_block = text[list_start: list_next if list_next != -1 else len(text)]

if "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE_BEGIN" not in read_block:
    raise SystemExit("FAIL: read gate not inside /public/jobs/{job_id} route")
if "_phase14ik_legacy_local_jobs_routes_enabled()" not in read_block:
    raise SystemExit("FAIL: read route does not use public local jobs helper")

if "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE_BEGIN" not in list_block:
    raise SystemExit("FAIL: list gate not inside /public/jobs route")
if "_phase14ik_legacy_local_jobs_routes_enabled()" not in list_block:
    raise SystemExit("FAIL: list route does not use public local jobs helper")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

for forbidden in [
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE",
    "_phase14ik_legacy_local_jobs_routes_enabled",
]:
    if forbidden in api_block:
        raise SystemExit(f"FAIL: /api/chat/queued contains Phase 14I-P marker/helper: {forbidden}")

print("PASS: public read/list gates are scoped correctly and not /api/chat/queued")
PY2

echo
echo "=== helper occurrence counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    "_phase14ik_legacy_local_jobs_routes_enabled(": 4,
    "_phase14ik_legacy_local_jobs_admin_archive_enabled(": 1,
    "_phase14ik_legacy_local_queue_status_enabled(": 2,
    "_phase14ik_legacy_companion_local_job_create_enabled(": 2,
    "_public_create_ollama_job(": 3,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

if bad:
    raise SystemExit(f"FAIL: unexpected helper/create counts: {bad}")

print("PASS: helper and local create counts match Phase 14I-P scope")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-p-gate-public-legacy-local-jobs-read-list-routes.md").read_text()

required = [
    "Phase 14I-P gates the public legacy local Edge `jobs` read/list route family",
    "`GET /public/jobs/{job_id}`",
    "`GET /public/jobs`",
    "`EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`",
    "Default remains enabled.",
    "`/api/chat/queued` is not changed by Phase 14I-P.",
    "Job 23 is not mutated.",
    "Job 23 is not forwarded to CT101.",
    "`POST /jobs`",
    "`GET /jobs`",
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
echo "=== done: Phase 14I-P public read/list gate smoke complete ==="
