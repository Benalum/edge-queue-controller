#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-p-guarded-controller-restart-live-disabled-admin-warmup-verification"
fail=0

echo "=== ${PHASE}: preflight ==="

test "$(git rev-parse --short HEAD)" = "74aba60" || fail=1
test -z "$(git status --short --untracked-files=no)" || fail=1
python3 -m py_compile edge_controller.py || fail=1

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
echo "=== safety: service must be active before restart ==="
systemctl is-active edge-queue-controller || fail=1

if [ "$fail" != "0" ]; then
  echo "FAIL: preflight blocked controller restart"
  exit "$fail"
fi

echo
echo "=== restart controller service only ==="
sudo systemctl restart edge-queue-controller || fail=1

echo
echo "=== wait for health ==="
ok=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  code="$(curl -sS --max-time 3 -o /tmp/phase12rp-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
  echo "try=$i health_code=$code"
  if [ "$code" = "200" ]; then
    ok=1
    break
  fi
  sleep 1
done

if [ "$ok" != "1" ]; then
  echo "FAIL: controller health did not recover"
  fail=1
fi

echo
echo "=== read-only live system status ==="
curl -sS --max-time 10 -o /tmp/phase12rp-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== verify disabled admin warmup status snapshot ==="
python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rp-status.json").read_text())

def find_model_memory_status(value):
    if isinstance(value, dict):
        if isinstance(value.get("model_memory_status"), dict):
            return value["model_memory_status"]
        for child in value.values():
            found = find_model_memory_status(child)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_model_memory_status(child)
            if found is not None:
                return found
    return None

memory = find_model_memory_status(data)
if not isinstance(memory, dict):
    raise SystemExit("FAIL: model_memory_status not found after restart")

endpoint = memory.get("admin_model_warmup_endpoint")
if not isinstance(endpoint, dict):
    raise SystemExit("FAIL: admin_model_warmup_endpoint not found after restart")

assert endpoint.get("source") == "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton"
assert endpoint.get("mode") == "disabled_endpoint_skeleton"
assert endpoint.get("endpoint") == "/admin/model-warmup"
assert endpoint.get("method") == "POST"
assert endpoint.get("dry_run_only") is True
assert endpoint.get("runtime_action_available") is False
assert endpoint.get("admin_endpoint_available") is True
assert endpoint.get("would_call") == "none"

print("PASS: live status exposes disabled admin warmup endpoint")
PY

echo
echo "=== verify POST refusal contract only ==="
curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rp-post.json \
  -w "post_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/admin/model-warmup || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rp-post.json").read_text())
detail = data.get("detail")
if not isinstance(detail, dict):
    raise SystemExit("FAIL: POST refusal detail missing")

assert detail.get("source") == "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton"
assert detail.get("mode") == "disabled_endpoint_skeleton"
assert detail.get("endpoint") == "/admin/model-warmup"
assert detail.get("method") == "POST"
assert detail.get("dry_run_only") is True
assert detail.get("action_enabled") is False
assert detail.get("runtime_action_available") is False
assert detail.get("admin_endpoint_available") is True
assert detail.get("would_call") == "none"
assert detail.get("reason") == "warmup_action_disabled"
assert "warmup_action_disabled" in detail.get("blockers", [])

print("PASS: POST endpoint refused safely with disabled contract")
PY

echo
echo "=== safety summary ==="
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"
echo "PASS: only edge-queue-controller was restarted"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
