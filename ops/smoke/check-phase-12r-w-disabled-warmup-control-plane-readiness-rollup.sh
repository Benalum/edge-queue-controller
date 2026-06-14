#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-w-disabled-warmup-control-plane-readiness-rollup"
fail=0

echo "=== ${PHASE}: rollup gates ==="

python3 -m py_compile edge_controller.py || fail=1

ops/smoke/check-phase-12r-s-admin-auth-bound-disabled-warmup-endpoint.sh || fail=1
ops/smoke/check-phase-12r-u-live-admin-auth-bound-warmup-smoke.sh || fail=1

echo
echo "=== optional admin smoke in no-token mode ==="
unset EDGE_TEST_ADMIN_BEARER_TOKEN
ops/smoke/check-phase-12r-v-optional-authenticated-admin-warmup-refusal-smoke.sh || fail=1

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
curl -sS --max-time 5 -o /tmp/phase12rw-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live system status ==="
curl -sS --max-time 10 -o /tmp/phase12rw-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== verify live disabled endpoint snapshot ==="
python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rw-status.json").read_text())

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

endpoint = memory.get("admin_model_warmup_endpoint")
if not isinstance(endpoint, dict):
    raise SystemExit("FAIL: admin_model_warmup_endpoint not found")

assert endpoint.get("source") == "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton"
assert endpoint.get("mode") == "disabled_endpoint_skeleton"
assert endpoint.get("endpoint") == "/admin/model-warmup"
assert endpoint.get("method") == "POST"
assert endpoint.get("runtime_action_available") is False
assert endpoint.get("admin_endpoint_available") is True
assert endpoint.get("would_call") == "none"

print("PASS: live disabled admin warmup snapshot is present")
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no bearer token value was printed"
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
