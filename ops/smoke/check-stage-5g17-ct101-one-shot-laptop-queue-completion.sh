#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-17 CT101 one-shot laptop queue completion ==="

echo
echo "=== syntax and local safety ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== CT101 one-shot worker prerequisites ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

cd /opt/ai-platform

test -f backend/app/worker/laptop_queue_client.py
test -f ops/smoke/laptop_queue_one_shot_worker.py
test -f .secrets/laptop-queue.env

grep -n "LAPTOP_QUEUE_ENABLED=1 is required" backend/app/worker/laptop_queue_client.py
grep -n "LAPTOP_QUEUE_SYNTHETIC_ONLY" backend/app/worker/laptop_queue_client.py
grep -n "/internal/laptop-queue/jobs/claim" backend/app/worker/laptop_queue_client.py
grep -n "/internal/laptop-queue/jobs/{job_id}/complete" backend/app/worker/laptop_queue_client.py || true

echo "ok: CT101 laptop queue one-shot prerequisites exist"
REMOTE

echo
echo "=== verify completed Stage 5G-17 one-shot laptop job ==="
python3 - <<'PY'
from edge_modules.chat_queue_persistence import _psql_at

needle = "Stage 5G-17 CT101 one-shot laptop queue worker reply exactly OK"

rows = _psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(result_json->>'reply', '') || E'\t' ||
  COALESCE(error_text, '') || E'\t' ||
  COALESCE(created_at::text, '')
FROM app_jobs
WHERE payload_json::text LIKE '%{needle}%'
ORDER BY created_at DESC
LIMIT 20;
""").strip()

print(rows)

if not rows:
    raise SystemExit("FAIL: no Stage 5G-17 one-shot jobs found")

completed = []
for line in rows.splitlines():
    parts = line.split("\t")
    while len(parts) < 6:
        parts.append("")
    job_id, status, worker_id, reply, error_text, created_at = parts[:6]
    if status == "complete" and worker_id == "ct101-stage5g17-one-shot" and reply and not error_text:
        completed.append(job_id)

if not completed:
    raise SystemExit("FAIL: no completed Stage 5G-17 one-shot job found with ct101-stage5g17-one-shot")

print("ok: completed Stage 5G-17 one-shot job(s): " + ", ".join(completed[:5]))
PY

echo
echo "=== verify user message exists for completed one-shot chat ==="
python3 - <<'PY'
from edge_modules.chat_queue_persistence import _psql_at

needle = "Stage 5G-17 CT101 one-shot laptop queue worker reply exactly OK"

rows = _psql_at(f"""
WITH completed AS (
  SELECT payload_json->>'chat_id' AS chat_id
  FROM app_jobs
  WHERE payload_json::text LIKE '%{needle}%'
    AND status = 'complete'
    AND assigned_worker_id = 'ct101-stage5g17-one-shot'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT
  role || E'\t' ||
  COUNT(*)::text
FROM app_messages
WHERE chat_id = (SELECT chat_id FROM completed)
GROUP BY role
ORDER BY role;
""").strip()

print(rows)

if "user\t1" not in rows:
    raise SystemExit("FAIL: expected exactly one user message for completed one-shot chat")

print("ok: one-shot user message exists")
PY

echo
echo "Stage 5G-17 CT101 one-shot laptop queue completion passed."
