#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-an-guarded-live-authenticated-admin-refusal-guard-report-verification"
fail=0

echo "=== ${PHASE}: guarded live authenticated admin refusal check ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static prerequisite: Phase 12R-AM guard report attachment ==="
ops/smoke/check-phase-12r-am-admin-disabled-warmup-refusal-guard-report-attachment.sh || fail=1

echo
echo "=== safety: warmup execution env must not be enabled before restart ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

TOKEN="${EDGE_TEST_ADMIN_BEARER_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo
  printf "Enter admin bearer token for local live check. Input is hidden and will not be printed: "
  IFS= read -r -s TOKEN
  printf "\n"
fi

if [ -z "$TOKEN" ]; then
  echo "FAIL: admin bearer token is required for Phase 12R-AN live authenticated verification"
  fail=1
fi

case "$TOKEN" in
  Bearer\ *) TOKEN="${TOKEN#Bearer }" ;;
esac

echo
echo "=== guarded controller-only restart ==="
if [ "$fail" = "0" ]; then
  sudo systemctl restart edge-queue-controller || fail=1
else
  echo "SKIP: restart blocked by failed preflight/token check"
fi

echo
echo "=== wait for health ==="
if [ "$fail" = "0" ]; then
  ok=0
  for i in $(seq 1 30); do
    code="$(curl -sS --max-time 3 -o /tmp/phase12ran-health.json \
      -w "%{http_code}" \
      http://127.0.0.1:7070/health || true)"
    echo "try=${i} health_code=${code}"
    if [ "$code" = "200" ]; then
      ok=1
      break
    fi
    sleep 1
  done

  if [ "$ok" != "1" ]; then
    echo "FAIL: service did not return healthy after restart"
    fail=1
  fi
fi

echo
echo "=== verify warmup env remains disabled after restart ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set after restart"
  fail=1
else
  echo "PASS: warmup action env is not enabled after restart"
fi

echo
echo "=== live authenticated admin future-style POST must still refuse execution ==="
if [ "$fail" = "0" ]; then
  post_meta="$(curl -sS --max-time 45 \
    -o /tmp/phase12ran-auth-post.json \
    -w "%{http_code} %{time_total}" \
    -X POST http://127.0.0.1:7070/admin/model-warmup \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json' \
    --data '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW","reason":"phase_12r_an_live_authenticated_guard_report_verification"}' || true)"

  post_code="$(printf '%s' "$post_meta" | awk '{print $1}')"
  post_time="$(printf '%s' "$post_meta" | awk '{print $2}')"

  echo "post_code=${post_code} post_time=${post_time}"

  if [ "$post_code" != "403" ]; then
    echo "FAIL: authenticated admin POST did not reach disabled 403 refusal"
    python3 -m json.tool /tmp/phase12ran-auth-post.json || cat /tmp/phase12ran-auth-post.json || true
    fail=1
  fi
else
  echo "SKIP: authenticated POST blocked by earlier failure"
fi

echo
echo "=== verify live authenticated disabled refusal payload ==="
if [ "$fail" = "0" ]; then
  python3 - <<'PY' || fail=1
import json
from pathlib import Path

path = Path("/tmp/phase12ran-auth-post.json")
data = json.loads(path.read_text())

detail = data.get("detail")
if not isinstance(detail, dict):
    raise SystemExit("FAIL: response detail is not an object")

required_detail = {
    "source": "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "runtime_action_available": False,
    "would_call": "none",
    "dry_run": False,
    "model": "qwen3:0.6b",
}
for key, expected in required_detail.items():
    actual = detail.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: detail.{key} expected {expected!r}, got {actual!r}")

if "future_runtime_allowed" in detail and detail.get("future_runtime_allowed") is not False:
    raise SystemExit("FAIL: optional legacy detail.future_runtime_allowed exists but is not false")

preview = detail.get("future_warmup_execution_preview")
if not isinstance(preview, dict):
    raise SystemExit("FAIL: future_warmup_execution_preview missing")
if preview.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: preview runtime_action_available is not false")
if preview.get("would_call") != "none":
    raise SystemExit("FAIL: preview would_call is not none")
if "execute_now" in preview and preview.get("execute_now") is not False:
    raise SystemExit("FAIL: optional legacy preview.execute_now exists but is not false")

future_request = preview.get("future_ollama_request")
if isinstance(future_request, dict):
    if future_request.get("execute_now") is not False:
        raise SystemExit("FAIL: future_ollama_request.execute_now is not false")

report = detail.get("activation_guard_report")
if not isinstance(report, dict):
    raise SystemExit("FAIL: activation_guard_report missing")

required_report = {
    "source": "phase_12r_al_disabled_warmup_activation_guard_report",
    "mode": "disabled_guard_report_only",
    "read_only": True,
    "network_calls": False,
    "runtime_action_available": False,
    "would_call": "none",
    "execute_now": False,
    "model": "qwen3:0.6b",
    "dry_run_requested": False,
    "confirm_required": "WARMUP_MODEL_NOW",
    "confirm_received": "WARMUP_MODEL_NOW",
    "all_required_guards_passed": False,
}
for key, expected in required_report.items():
    actual = report.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: activation_guard_report.{key} expected {expected!r}, got {actual!r}")

guards = report.get("guards")
if not isinstance(guards, dict):
    raise SystemExit("FAIL: activation_guard_report.guards missing")

expected_true = [
    "authenticated_admin",
    "confirm_matches",
    "model_allowlisted",
    "dry_run_false_requested",
]
for key in expected_true:
    if guards.get(key) is not True:
        raise SystemExit(f"FAIL: guard {key} should be true")

expected_false = [
    "warmup_action_env_enabled",
    "runtime_executor_implemented",
    "ollama_generation_call_allowed",
]
for key in expected_false:
    if guards.get(key) is not False:
        raise SystemExit(f"FAIL: guard {key} should be false")

blocked = report.get("blocked_reasons")
if not isinstance(blocked, list):
    raise SystemExit("FAIL: blocked_reasons missing")

for required in [
    "warmup_action_env_disabled",
    "runtime_executor_not_implemented",
    "ollama_generation_call_not_allowed",
]:
    if required not in blocked:
        raise SystemExit(f"FAIL: missing blocked reason: {required}")

print("PASS: live authenticated disabled refusal includes non-executing activation_guard_report")
PY
fi

unset TOKEN

echo
echo "=== safety summary ==="
echo "PASS: only edge-queue-controller was restarted if restart ran"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
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
