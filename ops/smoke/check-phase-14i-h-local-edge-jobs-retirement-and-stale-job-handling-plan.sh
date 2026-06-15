#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-h-local-edge-jobs-retirement-and-stale-job-handling-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-H local Edge jobs retirement and stale job handling plan ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -8
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== static retirement candidate route markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.get("/queue/summary")',
    '@app.post("/public/jobs")',
    '@app.get("/public/jobs/{job_id}")',
    '@app.get("/public/jobs")',
    '@app.post("/public/companion/chat")',
    '@app.post("/api/companion/chat")',
    '@app.get("/api/chat/queue/status")',
    '@app.get("/public/chat/queue/status")',
    'def _public_create_ollama_job',
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing retirement candidate markers: {missing}")

helper_start = text.index("def _public_create_ollama_job")
helper_end = text.index('@app.post("/public/jobs")', helper_start)
helper = text[helper_start:helper_end]
assert "INSERT INTO jobs" in helper, "legacy helper no longer writes local jobs"
assert "INSERT INTO app_jobs" not in helper, "legacy helper unexpectedly writes app_jobs"

status_start = text.index("async def public_chat_queue_status")
status_end = text.index('@app.post("/api/chat/queued")', status_start)
status_block = text[status_start:status_end]
assert "FROM jobs" in status_block, "queue status no longer reads local jobs; update retirement plan"

print("PASS: local Edge retirement candidates and helper/status ownership markers found")
PY

echo
echo "=== static canonical app_jobs route/module markers ==="
python3 - <<'PY'
from pathlib import Path

controller = Path("edge_controller.py").read_text()
assert '@app.post("/api/chat/queued")' in controller, "missing canonical queued chat route"
assert "from edge_modules.chat_queue_real_user_creation import" in controller, "missing real-user app job import"

for path in [
    Path("edge_modules/chat_queue_real_user_creation.py"),
    Path("edge_modules/chat_queue_persistence.py"),
    Path("edge_modules/laptop_queue.py"),
]:
    text = path.read_text()
    assert "INSERT INTO app_jobs" in text, f"{path} missing app_jobs insert"

real = Path("edge_modules/chat_queue_real_user_creation.py").read_text()
for marker in ["routing_contract_version", "model_lane", "queue_lane", "stage5p11r_build_model_lane_decision"]:
    assert marker in real, f"missing real-user lane marker: {marker}"

print("PASS: canonical app_jobs route/module markers found")
PY

echo
echo "=== redacted local Edge queue summary ==="
curl -sS --max-time 5 http://127.0.0.1:7070/queue/summary > /tmp/phase14ih-queue-summary.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ih-queue-summary.json").read_text())
counts = payload.get("counts") or {}
latest = payload.get("latest_jobs") or []

safe_jobs = []
for job in latest[:10]:
    prompt = job.get("prompt") or ""
    safe_jobs.append({
        "id": job.get("id"),
        "job_type": job.get("job_type"),
        "requested_model": job.get("requested_model"),
        "status": job.get("status"),
        "attempts": job.get("attempts"),
        "last_error_present": bool(job.get("last_error")),
        "created_at": job.get("created_at"),
        "updated_at": job.get("updated_at"),
        "forwarded_at": job.get("forwarded_at"),
        "user_id": job.get("user_id"),
        "prompt_length": len(prompt),
    })

print(json.dumps({"counts": counts, "latest_jobs_redacted": safe_jobs}, indent=2, sort_keys=True))
assert counts.get("queued") == 1, payload
assert any(job.get("id") == 23 and job.get("status") == "queued" for job in latest), payload
print("PASS: local Edge stale job 23 observed without raw prompt output")
PY

echo
echo "=== read-only CT101 app queue status ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status > /tmp/phase14ih-system-status.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ih-system-status.json").read_text())
services = payload.get("services") or []
worker = next((svc for svc in services if svc.get("id") == "ct101-laptop-queue-worker"), None)
if not worker:
    raise SystemExit("FAIL: ct101-laptop-queue-worker service missing")

queue = worker.get("queue") or {}
gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = gate.get("reasons") or []

assert worker.get("state") == "online", worker
assert queue.get("queued") == 0, queue
assert queue.get("running") == 0, queue
assert gate.get("ready") is False, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

print(json.dumps({
    "ct101_worker_state": worker.get("state"),
    "ct101_queue": {
        "queued": queue.get("queued"),
        "running": queue.get("running"),
        "complete": queue.get("complete"),
        "failed": queue.get("failed"),
    },
    "persistent_cutover_ready": gate.get("ready"),
    "persistent_cutover_reasons": reasons,
}, indent=2, sort_keys=True))
print("PASS: CT101 app queue remains separate and cutover remains blocked")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-h-local-edge-jobs-retirement-and-stale-job-handling-plan.md").read_text()

required = [
    "Do not delete or mutate job 23 yet.",
    "`POST /api/chat/queued` should not be blindly removed.",
    "`_public_create_ollama_job(...)` is the old local Edge job producer.",
    "Never forward job 23 to CT101 automatically",
    "Phase 14I-I: read-only active route proof for `/api/chat/queued`.",
]

missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY2

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|cat[[:space:]]+/tmp/phase14ih-queue-summary.json|tee[[:space:]]+/tmp/phase14ih-queue-summary.json' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
model_danger="$(
  grep -RInE 'curl.*(/api/generate|/api/chat|/admin/model-warmup)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ] || [ -n "$model_danger" ]; then
  [ -n "$danger" ] && echo "$danger"
  [ -n "$model_danger" ] && echo "$model_danger"
  echo "FAIL: smoke script contains mutation, model execution, or raw queue dump pattern"
  exit 1
fi
echo "PASS: read-only/privacy guard passed"

echo
echo "=== done: Phase 14I-H retirement plan smoke complete ==="
