#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PORT="${STAGE5G3_PORT:-17070}"
BASE="http://127.0.0.1:${PORT}"
LOG="/tmp/stage5g3-edge-controller-${PORT}.log"
PID_FILE="/tmp/stage5g3-edge-controller-${PORT}.pid"

cleanup() {
  if [ -f "$PID_FILE" ]; then
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$pid" ]; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
    rm -f "$PID_FILE"
  fi
}
trap cleanup EXIT

echo "=== Stage 5G-3 laptop controller queued-chat disabled guard ==="

echo
echo "=== static route registration ==="
python3 - <<'PYROUTES'
import edge_controller

seen = {}
for r in edge_controller.app.routes:
    path = getattr(r, "path", "")
    methods = set(getattr(r, "methods", []) or [])
    if path.startswith("/api/chat/queued"):
        seen[path] = methods
        print(path, sorted(methods))

if "/api/chat/queued" not in seen or "POST" not in seen["/api/chat/queued"]:
    raise SystemExit("missing POST /api/chat/queued route")

if "/api/chat/queued/{job_id}" not in seen or "GET" not in seen["/api/chat/queued/{job_id}"]:
    raise SystemExit("missing GET /api/chat/queued/{job_id} route")

print("queued chat routes registered")
PYROUTES

echo
echo "=== start fresh temporary controller on ${PORT} ==="
rm -f "$LOG" "$PID_FILE"
python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" > "$LOG" 2>&1 &
echo "$!" > "$PID_FILE"

for i in $(seq 1 40); do
  if curl -fsS "${BASE}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

curl -fsS "${BASE}/health" >/dev/null

echo
echo "=== GET disabled guard ==="
get_code="$(curl -s -o /tmp/stage5g3-get.json -w "%{http_code}" "${BASE}/api/chat/queued/stage5g3-smoke-job")"
cat /tmp/stage5g3-get.json
echo
echo "status=${get_code}"

python3 - <<'PYCHECK'
import json
from pathlib import Path

body = json.loads(Path("/tmp/stage5g3-get.json").read_text())
detail = body.get("detail", body)

if detail.get("error") != "feature_disabled":
    raise SystemExit(f"GET did not hit feature_disabled guard: {body}")

if detail.get("feature") != "laptop_queued_chat":
    raise SystemExit(f"GET wrong feature guard: {body}")

print("GET disabled guard ok")
PYCHECK

echo
echo "=== POST disabled guard ==="
post_code="$(curl -s -o /tmp/stage5g3-post.json -w "%{http_code}" \
  -X POST "${BASE}/api/chat/queued" \
  -H 'Content-Type: application/json' \
  --data '{}')"
cat /tmp/stage5g3-post.json
echo
echo "status=${post_code}"

python3 - <<'PYCHECK'
import json
from pathlib import Path

body = json.loads(Path("/tmp/stage5g3-post.json").read_text())
detail = body.get("detail", body)

if detail.get("error") != "feature_disabled":
    raise SystemExit(f"POST did not hit feature_disabled guard: {body}")

if detail.get("feature") != "laptop_queued_chat":
    raise SystemExit(f"POST wrong feature guard: {body}")

print("POST disabled guard ok")
PYCHECK

echo
echo "=== queued chat default remains off ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

echo
echo "=== frontend identity safety ==="
if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi
echo "ok: no forbidden identity references in app.js"

echo
echo "=== existing route ownership smoke ==="
bash ops/smoke/check-stage-5g2-laptop-wrapper-queued-chat-route-ownership.sh

echo
echo "Stage 5G-3 laptop controller queued-chat disabled guard passed."
