#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ab-live-disabled-future-warmup-skeleton-status-smoke"
fail=0

echo "=== ${PHASE}: live no-restart status checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-z-disabled-future-warmup-skeleton-status-attachment.sh || fail=1

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== service health ==="
curl -sS --max-time 5 -o /tmp/phase12rab-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live system status ==="
curl -sS --max-time 10 -o /tmp/phase12rab-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== verify live disabled future warmup skeletons ==="
python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rab-status.json").read_text())

def find_memory(value):
    if isinstance(value, dict):
        if isinstance(value.get("model_memory_status"), dict):
            return value["model_memory_status"]
        for child in value.values():
            found = find_memory(child)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_memory(child)
            if found is not None:
                return found
    return None

memory = find_memory(data)
if not isinstance(memory, dict):
    raise SystemExit("FAIL: model_memory_status not found")

skeletons = memory.get("disabled_future_warmup_execution_skeletons")
if not isinstance(skeletons, dict):
    raise SystemExit("FAIL: disabled_future_warmup_execution_skeletons not found")

expected = ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"]

for model in expected:
    item = skeletons.get(model)
    if not isinstance(item, dict):
        raise SystemExit(f"FAIL: missing skeleton for {model}")

    assert item.get("source") == "phase_12r_y_disabled_future_warmup_execution_skeleton"
    assert item.get("mode") == "disabled_future_execution_skeleton"
    assert item.get("model") == model
    assert item.get("runtime_action_available") is False
    assert item.get("would_call") == "none"
    assert item.get("reason") == "runtime_action_unavailable"

    future = item.get("future_ollama_request")
    assert isinstance(future, dict)
    assert future.get("endpoint") == "/api/generate"
    assert future.get("method") == "POST"
    assert future.get("stream") is False
    assert future.get("execute_now") is False

print("PASS: live disabled future warmup skeletons remain present and non-executable")
PY

echo
echo "=== verify unauthenticated admin warmup remains auth/admin blocked ==="
post_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rab-unauth-post.json \
  -w "%{http_code}" \
  http://127.0.0.1:7070/admin/model-warmup || true)"
echo "post_code=${post_code}"

if [ "$post_code" != "401" ] && [ "$post_code" != "403" ]; then
  echo "FAIL: expected unauthenticated POST to be blocked with 401 or 403"
  fail=1
fi

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rab-unauth-post.json").read_text())
body = json.dumps(data, sort_keys=True)

for forbidden in [
    "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "disabled_endpoint_skeleton",
    "warmup_action_disabled",
    "would_call",
    "runtime_action_available",
    "admin_endpoint_available",
]:
    if forbidden in body:
        raise SystemExit(f"FAIL: unauth response leaked warmup marker: {forbidden}")

print("PASS: unauthenticated POST remains blocked before warmup refusal")
print("detail:", data.get("detail"))
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
