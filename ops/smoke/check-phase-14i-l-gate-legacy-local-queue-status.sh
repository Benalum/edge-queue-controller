#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-l-gate-legacy-local-queue-status"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
SMOKE_K="ops/smoke/check-phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers.sh"

echo "=== Phase 14I-L gate legacy local queue status ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$SMOKE_K"
test -x "$SMOKE_K"
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
echo "=== static gate verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE_BEGIN",
    "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE_END",
    "_phase14ik_legacy_local_queue_status_enabled()",
    "legacy_local_queue_status_disabled",
    "legacy_local_jobs_disabled_phase_14i_l",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing queue-status gate markers: {missing}")

func_marker = "async def public_chat_queue_status"
func_start = text.index(func_marker)
next_route = text.find("\n@app.", func_start + 1)
func_block = text[func_start: next_route if next_route != -1 else len(text)]

if "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE_BEGIN" not in func_block:
    raise SystemExit("FAIL: queue-status gate not inside public_chat_queue_status")
if "_phase14ik_legacy_local_queue_status_enabled()" not in func_block:
    raise SystemExit("FAIL: queue-status helper not used inside public_chat_queue_status")

api_start = text.index('@app.post("/api/chat/queued")')
api_end = text.index('@app.get("/api/chat/queued/{job_id}")', api_start)
api_block = text[api_start:api_end]

if "PHASE_14I_L_LEGACY_LOCAL_QUEUE_STATUS_GATE" in api_block:
    raise SystemExit("FAIL: /api/chat/queued was modified by queue-status gate")
if "_phase14ik_legacy_local_queue_status_enabled" in api_block:
    raise SystemExit("FAIL: /api/chat/queued references legacy queue-status helper")

print("PASS: queue-status gate is scoped to legacy queue-status route and not /api/chat/queued")
PY2

echo
echo "=== helper occurrence counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    "_phase14ik_legacy_local_jobs_admin_archive_enabled(": 1,
    "_phase14ik_legacy_local_queue_status_enabled(": 2,
}

bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}

companion_marker = "_phase14ik_legacy_companion_local_job_create_enabled("
companion_count = text.count(companion_marker)
if companion_count == 1:
    pass
elif companion_count == 2:
    if "PHASE_14I_M_LEGACY_COMPANION_LOCAL_JOB_CREATE_GATE_BEGIN" not in text:
        bad[companion_marker] = {"expected": "1 or Phase 14I-M marked 2", "actual": companion_count}
else:
    bad[companion_marker] = {"expected": "1 or 2", "actual": companion_count}

public_marker = "_phase14ik_legacy_local_jobs_routes_enabled("
public_count = text.count(public_marker)
if public_count == 1:
    pass
elif public_count == 2:
    if "PHASE_14I_N_LEGACY_PUBLIC_LOCAL_JOBS_CREATE_GATE_BEGIN" not in text:
        bad[public_marker] = {"expected": "1 or Phase 14I-N marked 2", "actual": public_count}
elif public_count == 4:
    if "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_READ_GATE_BEGIN" not in text or "PHASE_14I_P_PUBLIC_LEGACY_LOCAL_JOBS_LIST_GATE_BEGIN" not in text:
        bad[public_marker] = {"expected": "Phase 14I-P marked 4", "actual": public_count}
else:
    bad[public_marker] = {"expected": "1, 2, or 4", "actual": public_count}

if bad:
    raise SystemExit(f"FAIL: unexpected helper occurrence counts: {bad}")

print("PASS: helper occurrence counts match Phase 14I-L scope or expected Phase 14I-M/14I-N evolution")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-l-gate-legacy-local-queue-status.md").read_text()

required = [
    "Phase 14I-L wires the read-only legacy local Edge queue-status endpoint",
    "`EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED`",
    "Default remains enabled.",
    "`/api/chat/queued` is not changed by Phase 14I-L.",
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
echo "=== done: Phase 14I-L queue-status gate smoke complete ==="
