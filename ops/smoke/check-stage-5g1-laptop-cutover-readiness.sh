#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-1 laptop cutover readiness ==="

echo
echo "=== syntax checks ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile public_gateway.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js
node --check frontend/wrapper-ui/queued_chat_status.js
node --check cloudflare/edge-public-proxy/src/index.js

echo
echo "=== queued chat default remains off ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

echo
echo "=== frontend app.js must not reference client-provided identity fields ==="
if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in frontend/wrapper-ui/app.js" >&2
  exit 1
fi
echo "ok: no forbidden identity references in app.js"

echo
echo "=== route markers ==="
grep -n 'PRIVATE_APP_ROUTE_SET' frontend/wrapper-ui/app.js
grep -n 'WRAPPER_ROUTES' frontend/wrapper-ui/dev_server.py
grep -n '"/calendar"' frontend/wrapper-ui/app.js frontend/wrapper-ui/dev_server.py

echo
echo "=== restore drill script exists ==="
test -x ops/db/verify-laptop-postgres-restore-drill.sh

echo
echo "=== existing queued-chat safety smoke ==="
bash ops/smoke/check-frontend-queued-chat-guarded-live-submit-branch-skeleton-mock-test.sh

echo
echo "Stage 5G-1 laptop cutover readiness passed."
