#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7J local authenticated runner offline implementation smoke ==="

fail=0

plan="docs/generated/stage-7j-local-authenticated-runner-offline-implementation-plan.json"
doc="docs/stage-7j-local-authenticated-runner-offline-implementation.md"
runner="ops/compare/run-authenticated-shadow-comparison.py"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
stage7i="docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json"

for f in \
  "$plan" \
  "$doc" \
  "$runner" \
  "$validator" \
  "$schema" \
  "$stage7i" \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7J plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7j-local-authenticated-runner-offline-implementation-plan.json").read_text())

assert data["stage"] == "7J"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

runner = data["runner"]
assert runner["path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert runner["created_in_this_stage"] is True
assert runner["manual_ops_tool_only"] is True
assert runner["offline_by_default"] is True
assert runner["authenticated_http_execution_requires_explicit_flag"] is True
assert runner["state_changing_route_call_requires_explicit_confirmation"] is True
assert runner["runtime_wired"] is False
assert runner["http_endpoint_exposed"] is False
assert runner["frontend_wired"] is False
assert runner["backend_wired"] is False
assert runner["gateway_wired"] is False
assert runner["systemd_wired"] is False

assert set(data["supported_domains"]) == {"study", "companion"}

cases = {item["case"]: item for item in data["supported_cases"]}
assert cases["study_next"]["domain"] == "study"
assert cases["study_next"]["route"] == "/api/study/session/command"
assert cases["study_next"]["helper"] == "_stage6q_study_adapter_shadow"
assert cases["companion_chat"]["domain"] == "companion"
assert cases["companion_chat"]["route"] == "/api/companion/chat"
assert cases["companion_chat"]["helper"] == "_stage6v_companion_adapter_shadow"

auth = data["auth_policy"]
assert auth["auth_required_only_for_execute_authenticated"] is True
assert "EDGE_AUTH_SHADOW_COMPARE_COOKIE" in auth["allowed_auth_environment"]
assert "EDGE_AUTH_SHADOW_COMPARE_BEARER" in auth["allowed_auth_environment"]
assert auth["secret_values_may_be_printed"] is False
assert auth["secret_values_may_be_stored"] is False
assert auth["raw_authenticated_response_stored"] is False

artifact = data["artifact_policy"]
assert artifact["schema_version"] == "stage-7c-v1"
assert artifact["validator"] == "ops/validate/validate-authenticated-shadow-comparison-artifact.py"
assert artifact["validate_before_success"] is True
assert artifact["store_raw_response"] is False
assert artifact["store_auth_values"] is False
assert artifact["store_secret_values"] is False

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7J plan JSON is valid")
PY

.venv/bin/python -m py_compile "$runner" "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== runner offline mode should generate valid Study artifact ==="
rm -f /tmp/stage7j-study-offline.json
.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output /tmp/stage7j-study-offline.json \
  > /tmp/stage7j-study-offline.out 2>&1

cat /tmp/stage7j-study-offline.out
python3 "$validator" /tmp/stage7j-study-offline.json

echo
echo "=== runner offline mode should generate valid Companion artifact ==="
rm -f /tmp/stage7j-companion-offline.json
.venv/bin/python "$runner" \
  --domain companion \
  --case companion_chat \
  --output /tmp/stage7j-companion-offline.json \
  > /tmp/stage7j-companion-offline.out 2>&1

cat /tmp/stage7j-companion-offline.out
python3 "$validator" /tmp/stage7j-companion-offline.json

echo
echo "=== validate offline artifact contents ==="
python3 - <<'PY'
import json
from pathlib import Path

for path, domain, intent, route, helper in [
    (
        Path("/tmp/stage7j-study-offline.json"),
        "study",
        "study.next",
        "/api/study/session/command",
        "_stage6q_study_adapter_shadow",
    ),
    (
        Path("/tmp/stage7j-companion-offline.json"),
        "companion",
        "companion.chat",
        "/api/companion/chat",
        "_stage6v_companion_adapter_shadow",
    ),
]:
    data = json.loads(path.read_text())
    assert data["stage"] == "7J"
    assert data["domain"] == domain
    assert data["runtime_behavior_change"] is False
    assert data["current_route_observation"]["route"] == route
    assert data["current_route_observation"]["http_status"] == 0
    assert data["current_route_observation"]["response_class"] == "offline_runner_not_executed"
    assert data["current_route_observation"]["raw_response_stored"] is False
    assert data["test_identity"]["real_user_secret_stored"] is False
    assert data["shadow_observation"]["helper"] == helper
    assert data["shadow_observation"]["intent"] == intent
    assert data["shadow_observation"]["model_call_required"] is False
    assert data["shadow_observation"]["allowed_to_dispatch"] is False
    assert data["shadow_observation"]["dispatch_performed"] is False
    assert data["shadow_observation"]["behavior_changed"] is False
    assert data["safety_observation"]["secrets_stored"] is False
    assert data["safety_observation"]["dispatch_enabled"] is False
    assert data["safety_observation"]["model_calls_enabled"] is False
    assert data["safety_observation"]["runtime_wiring_changed"] is False
    assert data["comparison_result"]["safe_to_continue"] is True

print("OK: Stage 7J offline artifacts are sanitized and safe")
PY

echo
echo "=== authenticated execution should fail closed without auth ==="
set +e
EDGE_AUTH_SHADOW_COMPARE_BASE_URL="http://127.0.0.1:7070" \
.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --execute-authenticated \
  --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE \
  --output /tmp/stage7j-noauth.json \
  > /tmp/stage7j-noauth.out 2>&1
noauth_code="$?"
set -e

cat /tmp/stage7j-noauth.out

if [ "$noauth_code" -eq 0 ]; then
  echo "FAIL: runner should fail closed without auth"
  fail=1
else
  echo "OK: runner failed closed without auth"
fi

echo
echo "=== runner must not print or store auth env values in offline mode ==="
secret_cookie="session=stage7j_super_secret_cookie_value_1234567890"
rm -f /tmp/stage7j-authenv-offline.json /tmp/stage7j-authenv-offline.out

EDGE_AUTH_SHADOW_COMPARE_COOKIE="$secret_cookie" \
.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output /tmp/stage7j-authenv-offline.json \
  > /tmp/stage7j-authenv-offline.out 2>&1

if grep -R "stage7j_super_secret_cookie_value_1234567890" /tmp/stage7j-authenv-offline.out /tmp/stage7j-authenv-offline.json >/dev/null 2>&1; then
  echo "FAIL: auth value leaked into output or artifact"
  fail=1
else
  echo "OK: auth value not printed or stored"
fi

python3 "$validator" /tmp/stage7j-authenv-offline.json

echo
echo "=== Stage 7J must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|stage-7j|stage_7j|EDGE_AUTH_SHADOW_COMPARE" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7J runner references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7J runner references not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7j-router-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"hello","source":"companion","surface":"companion_chat"},"context":{"active_page":"companion"}}' || true
  )"

  echo "router_disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: router endpoint remains disabled by default"
  else
    echo "FAIL: router endpoint should still be disabled by default"
    cat /tmp/stage7j-router-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped router disabled check"
fi

echo
echo "=== no runtime/systemd files should be modified ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)'; then
  echo "FAIL: runtime/systemd files modified"
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 7J local authenticated runner offline implementation smoke passed"
else
  echo "FAIL: Stage 7J local authenticated runner offline implementation smoke failed"
fi

exit "$fail"
