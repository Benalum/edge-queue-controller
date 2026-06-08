#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-2 laptop wrapper queued-chat route ownership ==="

echo
echo "=== syntax ==="
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js
node --check frontend/wrapper-ui/queued_chat_status.js

echo
echo "=== route marker exists ==="
grep -n "STAGE_5G2_LAPTOP_QUEUED_CHAT_CONTROLLER_OWNER_V1" frontend/wrapper-ui/dev_server.py

echo
echo "=== map_api ownership checks ==="
python3 - <<'PYMAP'
import importlib.util
import os
from pathlib import Path

os.environ["EDGE_CONTROLLER_URL"] = "http://controller.local"
os.environ["EDGE_PUBLIC_GATEWAY_URL"] = "http://gateway.local"
os.environ["CT101_API"] = "http://ct101-api.local"
os.environ["CT101_FRONTEND"] = "http://ct101-frontend.local"

path = Path("frontend/wrapper-ui/dev_server.py")
spec = importlib.util.spec_from_file_location("wrapper_dev_server_stage5g2", path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

checks = [
    ("/api/chat/queued", "http://controller.local", "/api/chat/queued"),
    ("/api/chat/queued/job-123", "http://controller.local", "/api/chat/queued/job-123"),
    ("/api/backend/chats/chat-1/messages/queued", "http://ct101-api.local", "/api/chats/chat-1/messages/queued"),
    ("/api/study/decks", "http://gateway.local", "/public/study/decks"),
    ("/api/companion/messages", "http://gateway.local", "/public/companion/messages"),
]

for original, expected_backend, expected_upstream in checks:
    backend, upstream = mod.map_api(original)
    if backend != expected_backend or upstream != expected_upstream:
        raise SystemExit(
            f"map_api mismatch for {original}: got {(backend, upstream)} expected {(expected_backend, expected_upstream)}"
        )
    print(f"ok: {original} -> {backend}{upstream}")
PYMAP

echo
echo "=== queued chat default remains off ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

echo
echo "=== frontend app.js identity safety ==="
if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi
echo "ok: no forbidden identity references in app.js"

echo
echo "=== existing Stage 5G-1 readiness smoke ==="
bash ops/smoke/check-stage-5g1-laptop-cutover-readiness.sh

echo
echo "Stage 5G-2 laptop wrapper queued-chat route ownership passed."
