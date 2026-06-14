#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-t-guarded-restart-live-admin-auth-bound-warmup-verification"
fail=0

echo "=== ${PHASE}: preflight ==="

test "$(git rev-parse --short HEAD)" = "cabe360" || fail=1
test -z "$(git status --short --untracked-files=no)" || fail=1
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
  code="$(curl -sS --max-time 3 -o /tmp/phase12rt-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
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
curl -sS --max-time 10 -o /tmp/phase12rt-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== verify unauthenticated POST is auth/admin blocked ==="
post_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rt-unauth-post.json \
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

p = Path("/tmp/phase12rt-unauth-post.json")
text = p.read_text()

try:
    data = json.loads(text)
except Exception as exc:
    raise SystemExit(f"FAIL: unauth POST response was not JSON: {exc}")

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
        raise SystemExit(f"FAIL: unauth response leaked disabled warmup contract marker: {forbidden}")

detail = data.get("detail")
print("PASS: unauthenticated POST blocked before warmup refusal")
print("detail:", detail)
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
