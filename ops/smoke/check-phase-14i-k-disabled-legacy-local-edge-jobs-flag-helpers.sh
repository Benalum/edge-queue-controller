#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
SMOKE_J="ops/smoke/check-phase-14i-j-disabled-legacy-local-edge-jobs-retirement-flag-plan.sh"

echo "=== Phase 14I-K disabled legacy local Edge jobs flag helpers ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$SMOKE_J"
test -x "$SMOKE_J"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -9
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== helper block and default behavior ==="
python3 - <<'PY2'
from pathlib import Path
import os

text = Path("edge_controller.py").read_text()

begin = "# PHASE_14I_K_LEGACY_LOCAL_JOBS_RETIREMENT_FLAG_HELPERS_BEGIN"
end = "# PHASE_14I_K_LEGACY_LOCAL_JOBS_RETIREMENT_FLAG_HELPERS_END"

if begin not in text or end not in text:
    raise SystemExit("FAIL: Phase 14I-K helper block markers missing")

block = text[text.index(begin):text.index(end) + len(end)]

required = [
    "EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED",
    "EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED",
    "EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED",
    "EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED",
    "def _phase14ik_env_bool",
    "def _phase14ik_legacy_local_jobs_routes_enabled",
    "def _phase14ik_legacy_companion_local_job_create_enabled",
    "def _phase14ik_legacy_local_queue_status_enabled",
    "def _phase14ik_legacy_local_jobs_admin_archive_enabled",
]
missing = [item for item in required if item not in block]
if missing:
    raise SystemExit(f"FAIL: missing helper markers: {missing}")

ns = {}
exec(block, ns, ns)

keys = [
    "EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED",
    "EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED",
    "EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED",
    "EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED",
]
old = {key: os.environ.get(key) for key in keys}

try:
    for key in keys:
        os.environ.pop(key, None)

    assert ns["_phase14ik_legacy_local_jobs_routes_enabled"]() is True
    assert ns["_phase14ik_legacy_companion_local_job_create_enabled"]() is True
    assert ns["_phase14ik_legacy_local_queue_status_enabled"]() is True
    assert ns["_phase14ik_legacy_local_jobs_admin_archive_enabled"]() is False

    os.environ["EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED"] = "0"
    os.environ["EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED"] = "false"
    os.environ["EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED"] = "off"
    os.environ["EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED"] = "1"

    assert ns["_phase14ik_legacy_local_jobs_routes_enabled"]() is False
    assert ns["_phase14ik_legacy_companion_local_job_create_enabled"]() is False
    assert ns["_phase14ik_legacy_local_queue_status_enabled"]() is False
    assert ns["_phase14ik_legacy_local_jobs_admin_archive_enabled"]() is True
finally:
    for key, value in old.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value

print("PASS: helper defaults and env override behavior verified in isolated execution")
PY2

echo
echo "=== helper wiring evolution check ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

helpers_definition_only = [
    "_phase14ik_legacy_local_jobs_admin_archive_enabled",
]

for helper in helpers_definition_only:
    count = text.count(helper + "(")
    if count != 1:
        raise SystemExit(f"FAIL: helper {helper} should only appear in its definition at this point, found {count}")

public_jobs_helper = "_phase14ik_legacy_local_jobs_routes_enabled"
public_jobs_count = text.count(public_jobs_helper + "(")

if public_jobs_count == 1:
    print("PASS: public local jobs routes helper not wired yet")
elif public_jobs_count == 2:
    if "PHASE_14I_N_LEGACY_PUBLIC_LOCAL_JOBS_CREATE_GATE_BEGIN" not in text:
        raise SystemExit("FAIL: public local jobs routes helper is wired without Phase 14I-N gate marker")
    print("PASS: Phase 14I-N public local jobs create helper wiring present")
elif public_jobs_count == 4:
    if "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE_BEGIN" not in text:
        raise SystemExit("FAIL: public local jobs routes helper has Phase 14I-P count without read gate marker")
    if "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE_BEGIN" not in text:
        raise SystemExit("FAIL: public local jobs routes helper has Phase 14I-P count without list gate marker")
    print("PASS: Phase 14I-P public local jobs read/list helper wiring present")
else:
    raise SystemExit(f"FAIL: unexpected public local jobs routes helper occurrence count: {public_jobs_count}")

queue_helper = "_phase14ik_legacy_local_queue_status_enabled"
queue_count = text.count(queue_helper + "(")

if queue_count == 1:
    print("PASS: queue status helper not wired yet")
elif queue_count == 2:
    if "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE_BEGIN" not in text:
        raise SystemExit("FAIL: queue status helper is wired without Phase 14I-L gate marker")
    print("PASS: Phase 14I-L queue-status helper wiring present")
else:
    raise SystemExit(f"FAIL: unexpected queue status helper occurrence count: {queue_count}")

companion_helper = "_phase14ik_legacy_companion_local_job_create_enabled"
companion_count = text.count(companion_helper + "(")

if companion_count == 1:
    print("PASS: Companion local job create helper not wired yet")
elif companion_count == 2:
    if "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_BEGIN" not in text:
        raise SystemExit("FAIL: Companion helper is wired without Phase 14I-M gate marker")
    print("PASS: Phase 14I-M Companion local job create helper wiring present")
else:
    raise SystemExit(f"FAIL: unexpected Companion helper occurrence count: {companion_count}")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

if any(helper in api_block for helper in helpers_definition_only + [queue_helper, companion_helper]):
    raise SystemExit("FAIL: /api/chat/queued should not be modified by legacy local jobs helpers")

print("PASS: /api/chat/queued remains untouched by legacy local jobs helper wiring")
PY2

echo
echo "=== Phase 14I-J smoke evolution marker ==="
grep -Fq "Phase 14I-K helper implementation present" "$SMOKE_J"
echo "PASS: Phase 14I-J smoke evolved for Phase 14I-K helper implementation"

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers.md").read_text()

required = [
    "Phase 14I-K adds disabled legacy local Edge `jobs` retirement flag helpers",
    "`EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`: default enabled",
    "`EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED`: default enabled",
    "`EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED`: default enabled",
    "`EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED`: default disabled",
    "The helpers are intentionally not wired into route handlers in Phase 14I-K.",
    "`/api/chat/queued` remains preserved.",
    "Do not archive job 23 yet.",
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
echo "=== done: Phase 14I-K helper smoke complete ==="
