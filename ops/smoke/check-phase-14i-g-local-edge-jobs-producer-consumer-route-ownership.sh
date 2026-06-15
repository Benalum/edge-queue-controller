#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-g-local-edge-jobs-producer-consumer-route-ownership"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-G local Edge jobs producer/consumer route ownership ==="

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
echo "=== static local Edge route markers ==="
grep -nF '@app.post("/jobs")' edge_controller.py
grep -nF '@app.get("/jobs")' edge_controller.py
grep -nF '@app.get("/queue/summary")' edge_controller.py
grep -nF '@app.post("/public/jobs")' edge_controller.py
grep -nF '@app.post("/public/companion/chat")' edge_controller.py
grep -nF '@app.post("/api/companion/chat")' edge_controller.py
grep -nF '@app.post("/api/chat/queued")' edge_controller.py
grep -nF 'def _public_create_ollama_job' edge_controller.py
echo "PASS: local Edge route markers found"

echo
echo "=== static local jobs table producer/consumer markers ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()
flat = " ".join(text.split())

required_literals = [
    "CREATE TABLE IF NOT EXISTS jobs",
    "INSERT INTO jobs",
    "def _public_create_ollama_job",
    "@app.get(\"/scheduler/preview\")",
    "def select_best_worker_for_job",
]

missing = [item for item in required_literals if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing local jobs literal markers: {missing}")

required_flat = [
    "SELECT * FROM jobs",
    "FROM jobs WHERE status = 'queued'",
    "INSERT INTO jobs (",
]

missing_flat = [item for item in required_flat if item not in flat]
if missing_flat:
    raise SystemExit(f"FAIL: missing local jobs normalized markers: {missing_flat}")

helper_start = text.index("def _public_create_ollama_job")
helper_end = text.index("@app.post(\"/public/jobs\")", helper_start)
helper = text[helper_start:helper_end]
assert "INSERT INTO jobs" in helper, "helper does not insert into local jobs"
assert "INSERT INTO app_jobs" not in helper, "helper unexpectedly inserts into app_jobs"

print("PASS: _public_create_ollama_job writes local jobs, not app_jobs")
print("PASS: local jobs producer/consumer markers found with whitespace-normalized checks")
PY2

echo
echo "=== static CT101 app_jobs markers ==="
python3 - <<'PY'
from pathlib import Path

files = [
    Path("edge_modules/chat_queue_creation.py"),
    Path("edge_modules/chat_queue_persistence.py"),
    Path("edge_modules/chat_queue_real_user_creation.py"),
    Path("edge_modules/laptop_queue.py"),
]

for path in files:
    if not path.exists():
        raise SystemExit(f"FAIL: missing {path}")
    text = path.read_text()
    if "INSERT INTO app_jobs" not in text:
        raise SystemExit(f"FAIL: {path} missing INSERT INTO app_jobs marker")

real = Path("edge_modules/chat_queue_real_user_creation.py").read_text()
for marker in [
    "routing_contract_version",
    "model_lane",
    "queue_lane",
    "stage5p11r_build_model_lane_decision",
]:
    if marker not in real:
        raise SystemExit(f"FAIL: real-user app_jobs lane marker missing: {marker}")

print("PASS: CT101 app_jobs producers and real-user lane metadata markers found")
PY

echo
echo "=== redacted local Edge queue summary ==="
curl -sS --max-time 5 http://127.0.0.1:7070/queue/summary > /tmp/phase14ig-queue-summary.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ig-queue-summary.json").read_text())
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
print("PASS: local Edge queued job 23 observed without raw prompt output")
PY

echo
echo "=== read-only scheduler preview ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview > /tmp/phase14ig-scheduler-preview.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ig-scheduler-preview.json").read_text())
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
echo "=== read-only CT101 app queue status ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status > /tmp/phase14ig-system-status.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ig-system-status.json").read_text())
services = payload.get("services") or []
worker = next((svc for svc in services if svc.get("id") == "ct101-laptop-queue-worker"), None)
if not worker:
    raise SystemExit("FAIL: ct101-laptop-queue-worker service missing")

queue = worker.get("queue") or {}
gate = worker.get("persistent_lane_cutover_readiness") or {}

assert worker.get("state") == "online", worker
assert queue.get("queued") == 0, queue
assert queue.get("running") == 0, queue
assert gate.get("ready") is False, gate
reasons = gate.get("reasons") or []
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
print("PASS: CT101 app queue remains separate with no queued/running work")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-g-local-edge-jobs-producer-consumer-route-ownership.md").read_text()

required = [
    "Job 23 being queued in local Edge",
    "Local Edge `jobs` and CT101 `app_jobs` are separate queues.",
    "Do not delete or mutate job 23 yet.",
    "Future smokes must use redacted summaries only.",
    "The next safe work should be a docs-only or read-only retirement plan",
]

missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY2

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|cat[[:space:]]+/tmp/phase14ig-queue-summary.json|tee[[:space:]]+/tmp/phase14ig-queue-summary.json' "$SELF" 2>/dev/null \
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
echo "=== done: Phase 14I-G route ownership smoke complete ==="
