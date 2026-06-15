#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-e-persistent-lane-readiness-field-attachment-surface"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-E persistent lane readiness field attachment surface ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -6
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== static attachment markers ==="
grep -nF '"persistent_lane_cutover_readiness": _stage5p12o_persistent_lane_cutover_readiness(registered_capacity)' edge_controller.py
grep -nF '"registered_capacity": registered_capacity' edge_controller.py
grep -nF '"lane_dispatch_readiness": _stage5p12f_lane_dispatch_readiness(registered_capacity)' edge_controller.py
echo "PASS: static attachment markers found"

echo
echo "=== live /system/status nested readiness proof ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status > /tmp/phase14ie-system-status.json

python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ie-system-status.json").read_text())
services = payload.get("services") or []
worker = next((svc for svc in services if svc.get("id") == "ct101-laptop-queue-worker"), None)
if not worker:
    raise SystemExit("FAIL: ct101-laptop-queue-worker service missing from /system/status")

gate = worker.get("persistent_lane_cutover_readiness")
if not isinstance(gate, dict):
    raise SystemExit("FAIL: persistent_lane_cutover_readiness missing from ct101 worker service")

reasons = gate.get("reasons") or []
warnings = gate.get("warnings") or []

assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate
assert "no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk" in warnings, gate

registered = worker.get("registered_capacity")
lane = worker.get("lane_dispatch_readiness")
assert isinstance(registered, dict), "registered_capacity missing"
assert isinstance(lane, dict), "lane_dispatch_readiness missing"

print("PASS: /system/status exposes nested persistent lane readiness and remains blocked")
PY

echo
echo "=== read-only worker registry still empty ==="
curl -sS --max-time 5 http://127.0.0.1:7070/workers/registry > /tmp/phase14ie-worker-registry.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ie-worker-registry.json").read_text())
summary = payload.get("summary") or {}
assert summary.get("total") == 0, payload
assert summary.get("available") == 0, payload
assert payload.get("workers") == [], payload
print("PASS: edge worker registry remains empty")
PY

echo
echo "=== read-only scheduler preview still blocked ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview > /tmp/phase14ie-scheduler-preview.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ie-scheduler-preview.json").read_text())
assert payload.get("queued_jobs") == 1, payload
assert payload.get("worker_count") == 0, payload
plans = payload.get("plans") or []
assert plans, payload
plan = plans[0]
assert plan.get("job_id") == 23, plan
assert plan.get("requested_model") == "gemma4:e4b", plan
assert plan.get("selected_worker") is None, plan
assert plan.get("candidates") == [], plan
print("PASS: scheduler preview remains blocked with no selected worker")
PY

echo
echo "=== documentation markers ==="
grep -Fq 'services[] -> id=ct101-laptop-queue-worker -> persistent_lane_cutover_readiness' "$DOC"
grep -Fq 'not exposed as a standalone controller readiness endpoint' "$DOC"
grep -Fq 'Do not enable workers yet' "$DOC"
grep -Fq 'Those are not the same registry surface' "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)|/api/chat|/admin/model-warmup' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains mutation or model execution pattern"
  exit 1
fi
echo "PASS: read-only guard passed"

echo
echo "=== done: Phase 14I-E readiness field attachment surface smoke complete ==="
