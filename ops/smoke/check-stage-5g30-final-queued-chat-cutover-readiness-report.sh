#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-30 final queued-chat cutover readiness report ==="

source .venv/bin/activate 2>/dev/null || true

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
echo "=== required docs and smokes exist ==="
for f in \
  docs/stage-5g27-live-browser-final-regression.md \
  docs/stage-5g28-runtime-invariant-smoke.md \
  docs/stage-5g29-runtime-restart-persistence-smoke.md \
  docs/stage-5g30-final-queued-chat-cutover-readiness-report.md \
  ops/smoke/check-stage-5g27-live-browser-final-regression.sh \
  ops/smoke/check-stage-5g28-runtime-invariant-smoke.sh \
  ops/smoke/check-stage-5g29-runtime-restart-persistence-smoke.sh \
  ops/smoke/check-stage-5g30-final-queued-chat-cutover-readiness-report.sh
do
  test -f "$f"
  echo "ok: $f"
done

echo
echo "=== git checkpoint and pushed tag verification ==="
HEAD_SHORT="$(git rev-parse --short HEAD)"
HEAD_FULL="$(git rev-parse HEAD)"
REMOTE_MAIN="$(git ls-remote --heads origin main | awk '{print $1}')"

echo "head_short=$HEAD_SHORT"
echo "head_full=$HEAD_FULL"
echo "remote_main=$REMOTE_MAIN"

if [ "$HEAD_FULL" != "$REMOTE_MAIN" ]; then
  echo "FAIL: origin/main does not match local HEAD" >&2
  exit 1
fi

for tag in \
  controller-stage-5g27-live-browser-final-regression-2026-06-08 \
  controller-stage-5g28-runtime-invariant-smoke-2026-06-08 \
  controller-stage-5g29-runtime-restart-persistence-smoke-2026-06-08
do
  if ! git tag --points-at HEAD | grep -q "$tag"; then
    if ! git ls-remote --tags origin "$tag" | grep -q "$tag"; then
      echo "FAIL: required tag missing locally/remotely: $tag" >&2
      exit 1
    fi
  fi
  git ls-remote --tags origin "$tag" | grep "$tag"
done

echo
echo "=== runtime invariant smoke must pass ==="
bash ops/smoke/check-stage-5g28-runtime-invariant-smoke.sh

echo
echo "=== verify latest managed worker completed jobs ==="
python3 - <<'PY'
from edge_modules.chat_queue_persistence import _psql_at

rows = _psql_at("""
SELECT
  id || E'\t' ||
  COALESCE(user_id, '') || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  LEFT(COALESCE(result_json->>'reply', ''), 80) || E'\t' ||
  COALESCE(updated_at::text, '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND assigned_worker_id = 'ct101-stage5g21-managed-browser'
ORDER BY created_at DESC
LIMIT 5;
""").strip()

print(rows)

if "complete" not in rows:
    raise SystemExit("FAIL: no recent completed managed-worker jobs found")
if "gemma4:e4b" not in rows:
    raise SystemExit("FAIL: managed-worker jobs did not use resolved model gemma4:e4b")
PY

echo
echo "=== verify wrapper reports managed worker online ==="
curl -fsS http://127.0.0.1:8787/api/system/status -o /tmp/stage5g30-wrapper-status.json

python3 - <<'PY'
import json

data = json.load(open("/tmp/stage5g30-wrapper-status.json"))

item = next(
    (
        x for x in data.get("normalized", {}).get("platform", [])
        if x.get("id") == "ct101-laptop-queue-worker"
    ),
    None,
)

if not item:
    raise SystemExit("FAIL: wrapper normalized platform missing worker")

print(json.dumps(item, indent=2))

if item.get("state") != "online":
    raise SystemExit(f"FAIL: worker expected online, got {item.get('state')!r}")

detail = item.get("detail") or ""
for needle in ["service: active", "preflight: ok", "paused: no", "model: gemma4:e4b", "max jobs/run: 1"]:
    if needle not in detail:
        raise SystemExit(f"FAIL: worker detail missing {needle!r}: {detail!r}")

print("ok: wrapper reports managed worker online")
PY

echo
echo "Stage 5G-30 final queued-chat cutover readiness report passed."
