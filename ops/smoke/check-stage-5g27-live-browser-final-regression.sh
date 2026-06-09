#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-27 live browser final regression ==="

source .venv/bin/activate 2>/dev/null || true

PROMPT="${STAGE5G27_PROMPT:-Stage 5G-27 live browser final regression $(date +%s) reply with exactly OK}"
PROMPT_FILE="/tmp/stage5g27-live-browser-prompt.txt"
echo "$PROMPT" > "$PROMPT_FILE"

echo
echo "=== syntax and safety ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1" edge_controller.py
grep -n "STAGE_5G26_NORMALIZED_WORKER_DETAIL_FIELD_V1" edge_controller.py
grep -n '"ct101-laptop-queue-worker"' frontend/wrapper-ui/app.js
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== live health ==="
curl -fsS http://127.0.0.1:7070/health >/tmp/stage5g27-controller-health.json
curl -fsS http://127.0.0.1:8787/api/system/status >/tmp/stage5g27-wrapper-status-before.json
echo "ok: controller and wrapper reachable"

echo
echo "=== verify managed worker online before browser test ==="
python3 - <<'PY'
import json

data = json.load(open("/tmp/stage5g27-wrapper-status-before.json"))
item = next(
    (
        x for x in data.get("normalized", {}).get("platform", [])
        if x.get("id") == "ct101-laptop-queue-worker"
    ),
    None,
)

if not item:
    raise SystemExit("FAIL: wrapper normalized platform missing ct101 worker")

print(json.dumps(item, indent=2))

if item.get("state") != "online":
    raise SystemExit(f"FAIL: worker expected online, got {item.get('state')!r}")

detail = item.get("detail") or ""
for needle in ["service: active", "preflight: ok", "paused: no", "model: gemma4:e4b", "queue: queued"]:
    if needle not in detail:
        raise SystemExit(f"FAIL: worker detail missing {needle!r}: {detail!r}")

print("ok: managed worker online before browser test")
PY

echo
echo "=== baseline exact prompt count ==="
python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

prompt = sys.argv[1]

count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("existing_exact_prompt_jobs=" + count)

if count != "0":
    raise SystemExit(f"FAIL: exact prompt already exists {count} time(s)")
PY

echo
echo "============================================================"
echo "MANUAL BROWSER STEP"
echo "============================================================"
echo "Open:"
echo
echo "  http://127.0.0.1:8787/chat?mode=chat"
echo
echo "In DevTools Console run:"
echo
echo '  localStorage.setItem("ai_chat_use_queued", "true");'
echo '  location.href = "/chat?mode=chat";'
echo
echo "Then send this exact prompt:"
echo
echo "  $PROMPT"
echo
echo "The prompt is saved at:"
echo "  $PROMPT_FILE"
echo
echo "Network should show:"
echo "  POST /api/backend/chats/.../messages/queued"
echo
echo "Waiting up to 360s for managed worker completion..."
echo "============================================================"
echo

deadline=$((SECONDS + 360))

while [ "$SECONDS" -lt "$deadline" ]; do
  set +e
  python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import json
import sys

prompt = sys.argv[1]

rows = _psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(user_id, '') || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  LEFT(COALESCE(result_json->>'reply', ''), 220) || E'\t' ||
  COALESCE(error_text, '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')}
ORDER BY created_at DESC
LIMIT 1;
""").strip()

if not rows:
    raise SystemExit(2)

print(rows)

parts = rows.split("\t")
if len(parts) < 6:
    raise SystemExit(3)

job_id, user_id, status, worker_id, requested_model, reply = parts[:6]
error_text = parts[6] if len(parts) > 6 else ""

if status == "complete":
    if not worker_id:
        raise SystemExit("FAIL: complete job missing worker_id")
    if requested_model == "default" or not requested_model:
        raise SystemExit("FAIL: requested_model was not resolved")
    if not reply:
        raise SystemExit("FAIL: complete job missing reply")
    if error_text:
        raise SystemExit(f"FAIL: complete job has error_text {error_text!r}")

    print()
    print("=== completed browser job ===")
    print(json.dumps({
        "job_id": job_id,
        "user_id": user_id,
        "status": status,
        "worker_id": worker_id,
        "requested_model": requested_model,
        "reply_preview": reply,
    }, indent=2))
    raise SystemExit(0)

if status in {"failed", "error"}:
    raise SystemExit(f"FAIL: browser job failed: {error_text}")

raise SystemExit(4)
PY
  rc=$?
  set -e

  if [ "$rc" = "0" ]; then
    echo
    echo "ok: browser-created job completed"
    break
  fi

  sleep 5
done

if [ "$SECONDS" -ge "$deadline" ]; then
  echo "FAIL: browser-created job did not complete within timeout" >&2
  echo
  echo "Recent matching jobs:"
  python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

prompt = sys.argv[1]

print(_psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  COALESCE(error_text, '') || E'\t' ||
  COALESCE(updated_at::text, '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')}
ORDER BY created_at DESC
LIMIT 10;
"""))
PY
  exit 1
fi

echo
echo "=== verify exactly one matching job and worker still online ==="
curl -fsS http://127.0.0.1:8787/api/system/status >/tmp/stage5g27-wrapper-status-after.json

python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import json
import sys

prompt = sys.argv[1]

count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("exact_prompt_job_count=" + count)

if count != "1":
    raise SystemExit(f"FAIL: expected exactly one matching job, got {count}")

data = json.load(open("/tmp/stage5g27-wrapper-status-after.json"))
item = next(
    (
        x for x in data.get("normalized", {}).get("platform", [])
        if x.get("id") == "ct101-laptop-queue-worker"
    ),
    None,
)

if not item:
    raise SystemExit("FAIL: wrapper normalized worker missing after browser test")

print(json.dumps(item, indent=2))

if item.get("state") != "online":
    raise SystemExit(f"FAIL: worker not online after browser test: {item.get('state')!r}")

print("ok: worker remained online after browser test")
PY

echo
echo "Stage 5G-27 live browser final regression passed."
