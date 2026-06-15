#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-q-direct-local-jobs-route-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-Q direct local jobs route inspection ==="

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
echo "=== static direct /jobs route inventory ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required_routes = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
]

bad_routes = {}
for route in required_routes:
    count = text.count(route)
    if count != 1:
        bad_routes[route] = count

if bad_routes:
    raise SystemExit(f"FAIL: missing or duplicate route markers: {bad_routes}")

def route_block(marker: str) -> str:
    start = text.index(marker)
    end = text.find("\n@app.", start + 1)
    return text[start: end if end != -1 else len(text)]

post_block = route_block('@app.post("/jobs")')
get_block = route_block('@app.get("/jobs")')

post_required = [
    "def create_job(payload: CreateEdgeJobRequest):",
    "INSERT INTO jobs",
    "SELECT * FROM jobs WHERE id = ?",
]
get_required = [
    "def list_jobs():",
    "SELECT * FROM jobs",
    '"jobs": [row_to_dict(row) for row in rows]',
]

missing_post = [item for item in post_required if item not in post_block]
missing_get = [item for item in get_required if item not in get_block]

if missing_post:
    raise SystemExit(f"FAIL: POST /jobs missing expected local jobs markers: {missing_post}")
if missing_get:
    raise SystemExit(f"FAIL: GET /jobs missing expected local jobs markers: {missing_get}")

for name, block in [("POST /jobs", post_block), ("GET /jobs", get_block)]:
    for forbidden in [
        "_phase14ik_",
        "PHASE_14I_",
        "Depends(",
        "require_admin",
        "admin",
        "auth",
        "user",
    ]:
        if forbidden in block:
            raise SystemExit(f"FAIL: {name} contains unexpected marker before decision phase: {forbidden}")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

for forbidden in [
    "PHASE_14I_Q",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE",
    "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE",
    "_phase14ik_legacy_local_jobs_routes_enabled",
]:
    if forbidden in api_block:
        raise SystemExit(f"FAIL: /api/chat/queued contains legacy direct jobs marker/helper: {forbidden}")

print("PASS: direct /jobs route inventory and /api/chat/queued preservation verified")
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

print("PASS: helper and local create counts match Phase 14I-Q inspection baseline")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-q-direct-local-jobs-route-inspection.md").read_text()

required = [
    "Phase 14I-Q records the static route-shape inspection",
    "`POST /jobs`",
    "`GET /jobs`",
    "No visible auth marker.",
    "No visible admin marker.",
    "No visible user marker.",
    "Job 23 is not mutated.",
    "`/api/chat/queued` is not changed by Phase 14I-Q.",
    "Phase 14I-R can inspect references/usages of the direct `/jobs` routes",
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
echo "=== done: Phase 14I-Q direct /jobs inspection smoke complete ==="
