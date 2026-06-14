#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-u-live-admin-auth-bound-warmup-smoke"
fail=0

echo "=== ${PHASE}: live admin-auth boundary smoke ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-s-admin-auth-bound-disabled-warmup-endpoint.sh || fail=1

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
curl -sS --max-time 5 -o /tmp/phase12ru-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live system status ==="
curl -sS --max-time 10 -o /tmp/phase12ru-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== verify live disabled status snapshot still exists ==="
python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12ru-status.json").read_text())

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
assert endpoint.get("endpoint") == "/admin/model-warmup"
assert endpoint.get("method") == "POST"
assert endpoint.get("runtime_action_available") is False
assert endpoint.get("admin_endpoint_available") is True
assert endpoint.get("would_call") == "none"

print("PASS: live status still exposes disabled admin warmup snapshot")
PY

echo
echo "=== verify unauthenticated POST is auth/admin blocked ==="
post_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12ru-unauth-post.json \
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

data = json.loads(Path("/tmp/phase12ru-unauth-post.json").read_text())
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

print("PASS: unauthenticated POST blocked before warmup refusal")
print("detail:", data.get("detail"))
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
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
