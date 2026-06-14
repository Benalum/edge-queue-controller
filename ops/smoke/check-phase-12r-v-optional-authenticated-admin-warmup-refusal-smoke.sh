#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-v-optional-authenticated-admin-warmup-refusal-smoke"
fail=0

echo "=== ${PHASE}: optional authenticated admin warmup refusal smoke ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-u-live-admin-auth-bound-warmup-smoke.sh || fail=1

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
curl -sS --max-time 5 -o /tmp/phase12rv-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== unauthenticated POST must be auth/admin blocked ==="
unauth_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":true}' \
  -o /tmp/phase12rv-unauth-post.json \
  -w "%{http_code}" \
  http://127.0.0.1:7070/admin/model-warmup || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: expected unauthenticated POST to be blocked with 401 or 403"
  fail=1
fi

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rv-unauth-post.json").read_text())
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
echo "=== optional authenticated admin POST disabled-refusal check ==="
if [ -z "${EDGE_TEST_ADMIN_BEARER_TOKEN:-}" ]; then
  echo "CHECK: EDGE_TEST_ADMIN_BEARER_TOKEN is not set"
  echo "CHECK: skipping authenticated admin disabled-refusal check"
else
  echo "CHECK: EDGE_TEST_ADMIN_BEARER_TOKEN is set; token value will not be printed"

  admin_code="$(curl -sS --max-time 8 \
    -H "Authorization: Bearer ${EDGE_TEST_ADMIN_BEARER_TOKEN}" \
    -H 'Content-Type: application/json' \
    -d '{"model":"qwen3:0.6b","dry_run":true}' \
    -o /tmp/phase12rv-admin-post.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/admin/model-warmup || true)"
  echo "admin_code=${admin_code}"

  if [ "$admin_code" != "403" ]; then
    echo "FAIL: expected authenticated admin POST to return disabled HTTP 403"
    fail=1
  fi

  python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rv-admin-post.json").read_text())
detail = data.get("detail")

if detail == "Admin access required.":
    raise SystemExit("FAIL: provided bearer token is valid but not admin")

if detail in ("Missing bearer token.", "Invalid or expired session."):
    raise SystemExit("FAIL: provided bearer token was missing, invalid, or expired")

if not isinstance(detail, dict):
    raise SystemExit(f"FAIL: expected disabled warmup detail object, got: {detail!r}")

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

print("PASS: authenticated admin reached disabled warmup refusal contract")
PY
fi

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
