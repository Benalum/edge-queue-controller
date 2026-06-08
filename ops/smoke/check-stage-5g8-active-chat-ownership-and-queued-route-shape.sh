#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-8 active chat ownership and queued route shape ==="

echo
echo "=== syntax ==="
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js
node --check frontend/wrapper-ui/queued_chat_status.js

echo
echo "=== frontend queued defaults remain off ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

echo
echo "=== /chat currently proxies to CT101 full app ==="
grep -n 'FULL_APP_ROUTES = {"/study", "/chat", "/companion", "/calendar", "/profile"}' frontend/wrapper-ui/dev_server.py
grep -n 'path in FULL_APP_ROUTES' frontend/wrapper-ui/dev_server.py

echo
echo "=== wrapper queued helper exists but must remain unwired ==="
grep -n 'AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH' frontend/wrapper-ui/app.js
grep -n 'wiredToSubmit: false' frontend/wrapper-ui/app.js
grep -n 'pollerWired: false' frontend/wrapper-ui/app.js
grep -n 'orchestrationWired: false' frontend/wrapper-ui/app.js

echo
echo "=== authForm is login/register and must not be queued target ==="
grep -n 'async function handleAuthSubmit' frontend/wrapper-ui/app.js
grep -n 'async function fastHandleAuthSubmit' frontend/wrapper-ui/app.js
grep -n '\$("authForm").addEventListener("submit", handleAuthSubmit);' frontend/wrapper-ui/app.js
grep -n 'document.addEventListener("submit", fastHandleAuthSubmit, true);' frontend/wrapper-ui/app.js

python3 - <<'PYCHECK'
from pathlib import Path
import re
import sys

text = Path("frontend/wrapper-ui/app.js").read_text()

# Extract auth submit windows and ensure queued orchestration is not called there.
windows = []
for marker in ["async function handleAuthSubmit", "async function fastHandleAuthSubmit"]:
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"missing {marker}")
    next_func = text.find("\nfunction ", start + 1)
    next_async = text.find("\nasync function ", start + 1)
    ends = [x for x in [next_func, next_async] if x > start]
    end = min(ends) if ends else min(len(text), start + 4000)
    windows.append(text[start:end])

bad_patterns = [
    "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH",
    "runQueuedChatSubmitOrchestration",
    "sendQueuedChat",
    "/api/chat/queued",
]

for window in windows:
    for pat in bad_patterns:
        if pat in window:
            raise SystemExit(f"auth submit window contains queued-chat pattern: {pat}")

print("OK: auth submit handlers do not call queued chat")
PYCHECK

echo
echo "=== wrapper app.js identity safety ==="
if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi
echo "ok: app.js has no forbidden identity references"

echo
echo "=== CT101 queued chat route shape, if reachable ==="
if ssh -o BatchMode=yes -o ConnectTimeout=5 root@100.88.194.19 'pct status 101 >/dev/null 2>&1'; then
  ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    set -e
    cd /opt/ai-platform

    echo === ChatPage queued call sites ===
    grep -RIn \"messages/queued\\|messages/jobs\\|queuedChatEnabled\\|ai_chat_use_queued\" frontend/components/ChatPage.tsx frontend/app/chat 2>/dev/null | sed -n \"1,220p\"

    echo
    echo === ChatPage queued source window ===
    sed -n \"520,690p\" frontend/components/ChatPage.tsx

    echo
    echo === backend queued route source window ===
    sed -n \"920,1085p\" backend/app/routes/chat.py
  "'
else
  echo "SKIP: CT101 not reachable by SSH; local ownership checks still passed"
fi

echo
echo "=== previous wrapper helper smoke ==="
bash ops/smoke/check-stage-5g7-browser-cookie-frontend-helper-through-wrapper.sh

echo
echo "Stage 5G-8 active chat ownership and queued route shape passed."
