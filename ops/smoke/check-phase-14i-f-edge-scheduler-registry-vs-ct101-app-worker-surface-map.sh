#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-f-edge-scheduler-registry-vs-ct101-app-worker-surface-map"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-F edge scheduler registry vs CT101 app worker surface map ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -7
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== static surface markers ==="
grep -nF '@app.get("/workers/registry")' edge_controller.py
grep -nF '@app.get("/scheduler/preview")' edge_controller.py
grep -nF '@app.get("/system/status")' edge_controller.py
grep -nF 'def _system_ct101_laptop_queue_worker_status' edge_controller.py
grep -nF 'def _stage5p11t_app_jobs_lane_summary' edge_controller.py
grep -nF 'def _stage5p12d_registered_laptop_queue_worker_capacity' edge_controller.py
echo "PASS: static surface markers found"

echo
echo "=== read-only edge worker registry ==="
curl -sS --max-time 5 http://127.0.0.1:7070/workers/registry > /tmp/phase14if-workers-registry.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14if-workers-registry.json").read_text())
summary = payload.get("summary") or {}
assert summary.get("total") == 0, payload
assert summary.get("available") == 0, payload
assert payload.get("workers") == [], payload
print("PASS: edge worker registry remains empty")
PY

echo
echo "=== read-only edge scheduler preview ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview > /tmp/phase14if-scheduler-preview.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14if-scheduler-preview.json").read_text())
assert payload.get("queued_jobs") == 1, payload
assert payload.get("worker_count") == 0, payload
plans = payload.get("plans") or []
assert plans, payload
plan = plans[0]
assert plan.get("job_id") == 23, plan
assert plan.get("requested_model") == "gemma4:e4b", plan
assert plan.get("selected_worker") is None, plan
assert plan.get("candidates") == [], plan
print("PASS: edge scheduler remains blocked with no selected worker")
PY

echo
echo "=== redacted edge queue summary, no raw prompt output ==="
curl -sS --max-time 5 http://127.0.0.1:7070/queue/summary > /tmp/phase14if-queue-summary.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14if-queue-summary.json").read_text())
counts = payload.get("counts") or {}
latest = payload.get("latest_jobs") or []
safe_jobs = []
for job in latest[:5]:
    prompt = job.get("prompt") or ""
    safe_jobs.append({
        "id": job.get("id"),
        "job_type": job.get("job_type"),
        "requested_model": job.get("requested_model"),
        "status": job.get("status"),
        "attempts": job.get("attempts"),
        "created_at": job.get("created_at"),
        "updated_at": job.get("updated_at"),
        "forwarded_at": job.get("forwarded_at"),
        "user_id": job.get("user_id"),
        "prompt_length": len(prompt),
    })
print(json.dumps({"counts": counts, "latest_jobs_redacted": safe_jobs}, indent=2, sort_keys=True))
assert counts.get("queued") == 1, payload
assert any(job.get("id") == 23 and job.get("status") == "queued" for job in latest), payload
print("PASS: queue summary inspected with prompt redaction")
PY

echo
echo "=== read-only CT101 app worker status from /system/status ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status > /tmp/phase14if-system-status.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14if-system-status.json").read_text())
services = payload.get("services") or []
worker = next((svc for svc in services if svc.get("id") == "ct101-laptop-queue-worker"), None)
if not worker:
    raise SystemExit("FAIL: ct101-laptop-queue-worker service missing")

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
lane = worker.get("lane_dispatch_readiness") or {}
gate = worker.get("persistent_lane_cutover_readiness") or {}
queue = worker.get("queue") or {}

assert worker.get("state") == "online", worker
assert worker.get("service_active") is True, worker
assert worker.get("worker_id") == "ct101-stage5g21-managed-browser", worker
assert caps.get("queue_lane") is None, caps
assert caps.get("supported_lanes") == ["model-tiny", "model-small"], caps
assert lane.get("claim_filter_enabled") is False, lane
assert gate.get("ready") is False, gate
reasons = gate.get("reasons") or []
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

safe = {
    "ct101_service_state": worker.get("state"),
    "ct101_service_active": worker.get("service_active"),
    "ct101_worker_id": worker.get("worker_id"),
    "ct101_worker_node_id": worker.get("worker_node_id"),
    "ct101_model": worker.get("model"),
    "ct101_queue": {
        "queued": queue.get("queued"),
        "running": queue.get("running"),
        "complete": queue.get("complete"),
        "failed": queue.get("failed"),
    },
    "ct101_registered_queue_lane": caps.get("queue_lane"),
    "ct101_supported_lanes": caps.get("supported_lanes"),
    "ct101_allowed_models": caps.get("allowed_models"),
    "lane_dispatch_claim_filter_enabled": lane.get("claim_filter_enabled"),
    "persistent_cutover_ready": gate.get("ready"),
    "persistent_cutover_reasons": reasons,
    "persistent_cutover_warnings": gate.get("warnings") or [],
}
print(json.dumps(safe, indent=2, sort_keys=True))
print("PASS: CT101 app worker surface remains online but persistent cutover remains blocked")
PY

echo
echo "=== documentation markers ==="
grep -Fq "There are two different worker/queue surfaces." "$DOC"
grep -Fq "The CT101 app worker being online does not populate the Edge Queue Controller" "$DOC"
grep -Fq 'raw `/queue/summary` can expose full queued prompt/context bodies' "$DOC"
grep -Fq "Do not enable workers yet." "$DOC"
grep -Fq "The Edge scheduler uses the Edge worker registry" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)|/api/chat|/admin/model-warmup|cat[[:space:]]+/tmp/phase14if-queue-summary.json|tee[[:space:]]+/tmp/phase14if-queue-summary.json' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains mutation, model execution, or raw queue dump pattern"
  exit 1
fi
echo "PASS: read-only/privacy guard passed"

echo
echo "=== done: Phase 14I-F surface map smoke complete ==="
