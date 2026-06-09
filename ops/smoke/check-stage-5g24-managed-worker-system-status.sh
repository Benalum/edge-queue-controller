#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-24 managed worker system status verification ==="

source .venv/bin/activate 2>/dev/null || true

echo
echo "=== syntax and markers ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1" edge_controller.py
grep -n "ct101-laptop-queue-worker" edge_controller.py

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== fetch controller and wrapper statuses ==="
curl -fsS http://127.0.0.1:7070/system/status -o /tmp/stage5g24-controller-status.json
curl -fsS http://127.0.0.1:8787/api/system/status -o /tmp/stage5g24-wrapper-status.json

echo
echo "=== verify managed worker status ==="
python3 - <<'PY'
import json

controller = json.load(open("/tmp/stage5g24-controller-status.json"))
wrapper = json.load(open("/tmp/stage5g24-wrapper-status.json"))

controller_services = controller.get("services", [])
controller_platform = controller.get("normalized", {}).get("platform", [])
wrapper_platform = wrapper.get("normalized", {}).get("platform", [])

svc = next((x for x in controller_services if x.get("id") == "ct101-laptop-queue-worker"), None)
controller_item = next((x for x in controller_platform if x.get("id") == "ct101-laptop-queue-worker"), None)
wrapper_item = next((x for x in wrapper_platform if x.get("id") == "ct101-laptop-queue-worker"), None)

if not svc:
    raise SystemExit("FAIL: controller services missing ct101-laptop-queue-worker")
if not controller_item:
    raise SystemExit("FAIL: controller normalized platform missing ct101-laptop-queue-worker")
if not wrapper_item:
    raise SystemExit("FAIL: wrapper normalized platform missing ct101-laptop-queue-worker")

print("--- controller service ---")
print(json.dumps(svc, indent=2))
print("--- controller normalized item ---")
print(json.dumps(controller_item, indent=2))
print("--- wrapper normalized item ---")
print(json.dumps(wrapper_item, indent=2))

if svc.get("state") != "online":
    raise SystemExit(f"FAIL: controller worker state expected online, got {svc.get('state')!r}")
if controller_item.get("state") != "online":
    raise SystemExit(f"FAIL: controller normalized state expected online, got {controller_item.get('state')!r}")
if wrapper_item.get("state") != "online":
    raise SystemExit(f"FAIL: wrapper normalized state expected online, got {wrapper_item.get('state')!r}")
if svc.get("service_active") is not True:
    raise SystemExit("FAIL: service_active was not true")
if svc.get("preflight_ok") is not True:
    raise SystemExit("FAIL: preflight_ok was not true")
if svc.get("paused") is not False:
    raise SystemExit("FAIL: paused was not false")
if svc.get("model") != "gemma4:e4b":
    raise SystemExit(f"FAIL: model expected gemma4:e4b, got {svc.get('model')!r}")
if svc.get("max_jobs_per_run") != 1:
    raise SystemExit(f"FAIL: max_jobs_per_run expected 1, got {svc.get('max_jobs_per_run')!r}")

queue = svc.get("queue") or {}
for key in ["queued", "running", "complete", "failed"]:
    if key not in queue:
        raise SystemExit(f"FAIL: queue missing {key!r}")

print("ok: managed worker status is visible through controller service and wrapper normalized platform")
PY

echo
echo "Stage 5G-24 managed worker system status verification passed."
