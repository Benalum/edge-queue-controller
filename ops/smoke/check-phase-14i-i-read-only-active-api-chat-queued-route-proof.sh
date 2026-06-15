#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-i-read-only-active-api-chat-queued-route-proof"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-I read-only active /api/chat/queued route proof ==="

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
echo "=== static /api/chat/queued route ownership proof ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

create_marker = '@app.post("/api/chat/queued")'
status_marker = '@app.get("/api/chat/queued/{job_id}")'

if create_marker not in text:
    raise SystemExit("FAIL: missing POST /api/chat/queued route")
if status_marker not in text:
    raise SystemExit("FAIL: missing GET /api/chat/queued/{job_id} route")

create_start = text.index(create_marker)
create_end = text.index(status_marker, create_start)
create_block = text[create_start:create_end]

checks = {
    "calls_real_user_app_jobs_helper": "_s5f19_create_real_user_queued_chat_job" in create_block,
    "calls_synthetic_app_jobs_helper": "_s5f9_create_synthetic_queued_chat_job" in create_block,
    "does_not_call_legacy_public_create": "_public_create_ollama_job" not in create_block,
    "does_not_directly_insert_local_jobs": "INSERT INTO jobs" not in create_block,
    "checks_enabled_gate": "_s5f9_laptop_chat_queue_enabled" in create_block,
    "checks_real_user_gate": "_s5f14_laptop_chat_queue_real_users_enabled" in create_block,
    "checks_synthetic_gate": "_s5f9_laptop_chat_queue_synthetic_only" in create_block,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit(f"FAIL: /api/chat/queued route proof failed: {failed}")

status_start = text.index(status_marker)
next_route = text.find("\n@app.", status_start + 1)
status_block = text[status_start: next_route if next_route != -1 else len(text)]

if "FROM app_jobs" not in status_block:
    raise SystemExit("FAIL: queued status route does not show app_jobs status lookup")
if "FROM jobs" in status_block:
    raise SystemExit("FAIL: queued status route unexpectedly references local jobs table")

print("PASS: /api/chat/queued create/status routes are app_jobs-oriented, not legacy local jobs")
PY

echo
echo "=== static app_jobs helper/module proof ==="
python3 - <<'PY'
from pathlib import Path

controller = Path("edge_controller.py").read_text()
required_controller = [
    "from edge_modules.chat_queue_real_user_creation import",
    "create_real_user_queued_chat_job as _s5f19_create_real_user_queued_chat_job",
    "_s5f19_create_real_user_queued_chat_job",
]

missing = [item for item in required_controller if item not in controller]
if missing:
    raise SystemExit(f"FAIL: missing controller app_jobs helper markers: {missing}")

for path in [
    Path("edge_modules/chat_queue_real_user_creation.py"),
    Path("edge_modules/chat_queue_persistence.py"),
    Path("edge_modules/laptop_queue.py"),
]:
    text = path.read_text()
    if "INSERT INTO app_jobs" not in text:
        raise SystemExit(f"FAIL: {path} missing INSERT INTO app_jobs")

real = Path("edge_modules/chat_queue_real_user_creation.py").read_text()
for marker in [
    "routing_contract_version",
    "model_lane",
    "queue_lane",
    "stage5p11r_build_model_lane_decision",
]:
    if marker not in real:
        raise SystemExit(f"FAIL: missing real-user app_jobs lane marker: {marker}")

print("PASS: app_jobs helper imports, inserts, and lane metadata markers found")
PY

echo
echo "=== secret-safe queued chat flag snapshot ==="
systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -E '^(LAPTOP_CHAT_QUEUE|LAPTOP_QUEUE|EDGE_|AI_PLATFORM_)' \
  | grep -Ev 'SECRET|TOKEN|KEY|PASSWORD|COOKIE|AUTH|CREDENTIAL|PRIVATE' \
  | sort || true
echo "PASS: secret-safe flag snapshot printed"

echo
echo "=== redacted local Edge queue summary ==="
curl -sS --max-time 5 http://127.0.0.1:7070/queue/summary > /tmp/phase14ii-queue-summary.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ii-queue-summary.json").read_text())
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
        "last_error_present": bool(job.get("last_error")),
        "forwarded_at": job.get("forwarded_at"),
        "user_id": job.get("user_id"),
        "prompt_length": len(prompt),
    })

print(json.dumps({"counts": counts, "latest_jobs_redacted": safe_jobs}, indent=2, sort_keys=True))
assert counts.get("queued") == 1, payload
assert any(job.get("id") == 23 and job.get("status") == "queued" for job in latest), payload
print("PASS: local Edge job 23 observed without raw prompt output")
PY

echo
echo "=== read-only CT101 app queue status ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status > /tmp/phase14ii-system-status.json
python3 - <<'PY'
import json
from pathlib import Path

payload = json.loads(Path("/tmp/phase14ii-system-status.json").read_text())
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

print(json.dumps({
    "ct101_worker_state": worker.get("state"),
    "ct101_queue": {
        "queued": queue.get("queued"),
        "running": queue.get("running"),
        "complete": queue.get("complete"),
        "failed": queue.get("failed"),
    },
    "persistent_cutover_ready": gate.get("ready"),
    "persistent_cutover_reasons": gate.get("reasons") or [],
}, indent=2, sort_keys=True))
print("PASS: CT101 app queue remains separate")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-i-read-only-active-api-chat-queued-route-proof.md").read_text()

required = [
    "`/api/chat/queued` should not be retired with the old local Edge `jobs` routes.",
    "route calls legacy `_public_create_ollama_job`: false",
    "route directly inserts into local `jobs`: false",
    "This phase intentionally did not POST to `/api/chat/queued`.",
    "Do not retire `/api/chat/queued` as part of local Edge jobs cleanup.",
    "Phase 14I-J should add a disabled-by-default legacy local Edge jobs retirement flag plan.",
]

missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|cat[[:space:]]+/tmp/phase14ii-queue-summary.json|tee[[:space:]]+/tmp/phase14ii-queue-summary.json' "$SELF" 2>/dev/null \
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
echo "=== done: Phase 14I-I route proof smoke complete ==="
