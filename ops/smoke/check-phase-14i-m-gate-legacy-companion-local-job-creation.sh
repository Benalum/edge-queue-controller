#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-m-gate-legacy-companion-local-job-creation"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
SMOKE_K="ops/smoke/check-phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers.sh"
SMOKE_L="ops/smoke/check-phase-14i-l-gate-legacy-local-queue-status.sh"

echo "=== Phase 14I-M gate legacy Companion local job creation ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$SMOKE_K"
test -x "$SMOKE_K"
test -f "$SMOKE_L"
test -x "$SMOKE_L"
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
echo "=== static Companion gate verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_BEGIN",
    "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_END",
    "_phase14ik_legacy_companion_local_job_create_enabled()",
    "legacy_companion_local_job_create_disabled",
    "legacy_local_jobs_disabled_phase_14i_m",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Companion local job create gate markers: {missing}")

route_marker = '@app.post("/public/companion/chat")'
api_route_marker = '@app.post("/api/companion/chat")'
if route_marker not in text or api_route_marker not in text:
    raise SystemExit("FAIL: missing Companion route decorators")

route_start = text.index(route_marker)
next_route = text.find("\n@app.", route_start + 1)
while next_route != -1 and text[next_route + 1:].startswith(api_route_marker):
    next_route = text.find("\n@app.", next_route + 1)
route_block = text[route_start: next_route if next_route != -1 else len(text)]

if "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_BEGIN" not in route_block:
    raise SystemExit("FAIL: Companion create gate not inside legacy Companion route block")
if "_phase14ik_legacy_companion_local_job_create_enabled()" not in route_block:
    raise SystemExit("FAIL: Companion helper not used inside legacy Companion route block")
if "_public_create_ollama_job(" not in route_block:
    raise SystemExit("FAIL: legacy Companion route no longer shows local job create helper; update phase plan")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

if "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE" in api_block:
    raise SystemExit("FAIL: /api/chat/queued was modified by Companion local job create gate")
if "_phase14ik_legacy_companion_local_job_create_enabled" in api_block:
    raise SystemExit("FAIL: /api/chat/queued references Companion legacy helper")

print("PASS: Companion gate is scoped to legacy Companion local job creation and not /api/chat/queued")
PY2

echo
echo "=== helper occurrence counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    "_phase14ik_legacy_local_jobs_routes_enabled(": 1,
    "_phase14ik_legacy_local_jobs_admin_archive_enabled(": 1,
    "_phase14ik_legacy_local_queue_status_enabled(": 2,
    "_phase14ik_legacy_companion_local_job_create_enabled(": 2,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

if bad:
    raise SystemExit(f"FAIL: unexpected helper occurrence counts: {bad}")

print("PASS: helper occurrence counts match Phase 14I-M scope")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-m-gate-legacy-companion-local-job-creation.md").read_text()

required = [
    "Phase 14I-M wires the old Companion local Edge job creation routes",
    "`EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED`",
    "Default remains enabled.",
    "`/api/chat/queued` is not changed by Phase 14I-M.",
    "Job 23 is not mutated.",
    "Job 23 is not forwarded to CT101.",
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
echo "=== done: Phase 14I-M Companion gate smoke complete ==="
