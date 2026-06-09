#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-26 normalized managed worker detail ==="

source .venv/bin/activate 2>/dev/null || true

echo
echo "=== syntax and markers ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1" edge_controller.py
grep -n "STAGE_5G26_NORMALIZED_WORKER_DETAIL_QUEUE_SUMMARY_V1" edge_controller.py
grep -n "STAGE_5G26_NORMALIZED_WORKER_DETAIL_FIELD_V1" edge_controller.py
grep -n '"ct101-laptop-queue-worker"' frontend/wrapper-ui/app.js
grep -n "detail: item.detail || NORMALIZED_PLATFORM_DETAILS" frontend/wrapper-ui/app.js
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== fetch live statuses ==="
curl -fsS http://127.0.0.1:7070/system/status -o /tmp/stage5g26-controller-status.json
curl -fsS http://127.0.0.1:8787/api/system/status -o /tmp/stage5g26-wrapper-status.json

python3 - <<'PY'
import json

required = [
    "service: active",
    "preflight: ok",
    "paused: no",
    "model: gemma4:e4b",
    "max jobs/run: 1",
    "queue: queued",
    "running",
    "failed",
]

for label, path in [
    ("controller", "/tmp/stage5g26-controller-status.json"),
    ("wrapper", "/tmp/stage5g26-wrapper-status.json"),
]:
    data = json.load(open(path))

    item = next(
        (
            x for x in data.get("normalized", {}).get("platform", [])
            if x.get("id") == "ct101-laptop-queue-worker"
        ),
        None,
    )

    if not item:
        raise SystemExit(f"FAIL: {label} missing normalized worker item")

    print(f"--- {label} normalized worker ---")
    print(json.dumps(item, indent=2))

    if item.get("state") != "online":
        raise SystemExit(f"FAIL: {label} worker state expected online, got {item.get('state')!r}")

    detail = item.get("detail") or ""
    if not detail:
        raise SystemExit(f"FAIL: {label} worker detail is missing")

    for needle in required:
        if needle not in detail:
            raise SystemExit(f"FAIL: {label} detail missing {needle!r}: {detail!r}")

    forbidden = ["token", "secret", "password", "prompt", "message content"]
    lowered = detail.lower()
    for bad in forbidden:
        if bad in lowered:
            raise SystemExit(f"FAIL: {label} detail contains forbidden text {bad!r}")

print("ok: normalized worker detail is visible through controller and wrapper")
PY

echo
echo "Stage 5G-26 normalized managed worker detail passed."
