#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-25 managed worker System drawer detail ==="

source .venv/bin/activate 2>/dev/null || true

echo
echo "=== syntax and markers ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1" edge_controller.py
grep -n '"ct101-laptop-queue-worker"' frontend/wrapper-ui/app.js
grep -n "Managed CT101 worker processing queued chat jobs" frontend/wrapper-ui/app.js
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== verify live normalized worker status ==="
curl -fsS http://127.0.0.1:7070/system/status -o /tmp/stage5g25-controller-status.json
curl -fsS http://127.0.0.1:8787/api/system/status -o /tmp/stage5g25-wrapper-status.json

python3 - <<'PY'
import json
from pathlib import Path

app = Path("frontend/wrapper-ui/app.js").read_text()

if '"ct101-laptop-queue-worker"' not in app:
    raise SystemExit("FAIL: app.js missing ct101 worker id")
if "Managed CT101 worker processing queued chat jobs" not in app:
    raise SystemExit("FAIL: app.js missing ct101 worker detail text")

controller = json.load(open("/tmp/stage5g25-controller-status.json"))
wrapper = json.load(open("/tmp/stage5g25-wrapper-status.json"))

controller_platform = controller.get("normalized", {}).get("platform", [])
wrapper_platform = wrapper.get("normalized", {}).get("platform", [])

controller_item = next((x for x in controller_platform if x.get("id") == "ct101-laptop-queue-worker"), None)
wrapper_item = next((x for x in wrapper_platform if x.get("id") == "ct101-laptop-queue-worker"), None)

if not controller_item:
    raise SystemExit("FAIL: controller normalized platform missing worker")
if not wrapper_item:
    raise SystemExit("FAIL: wrapper normalized platform missing worker")

print("--- controller normalized worker ---")
print(json.dumps(controller_item, indent=2))
print("--- wrapper normalized worker ---")
print(json.dumps(wrapper_item, indent=2))

if controller_item.get("state") != "online":
    raise SystemExit(f"FAIL: controller worker state expected online, got {controller_item.get('state')!r}")
if wrapper_item.get("state") != "online":
    raise SystemExit(f"FAIL: wrapper worker state expected online, got {wrapper_item.get('state')!r}")

print("ok: managed worker is visible to the System drawer normalized platform path")
PY

echo
echo "Stage 5G-25 managed worker System drawer detail passed."
