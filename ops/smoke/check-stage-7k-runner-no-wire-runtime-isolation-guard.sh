#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7K runner no-wire runtime isolation guard smoke ==="

fail=0

guard="docs/generated/stage-7k-runner-no-wire-runtime-isolation-guard.json"
doc="docs/stage-7k-runner-no-wire-runtime-isolation-guard.md"
runner="ops/compare/run-authenticated-shadow-comparison.py"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
stage7j="docs/generated/stage-7j-local-authenticated-runner-offline-implementation-plan.json"
stage7j_doc="docs/stage-7j-local-authenticated-runner-offline-implementation.md"
stage7j_smoke="ops/smoke/check-stage-7j-local-authenticated-runner-offline-implementation.sh"

for f in \
  "$guard" \
  "$doc" \
  "$runner" \
  "$validator" \
  "$stage7j" \
  "$stage7j_doc" \
  "$stage7j_smoke" \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7K guard json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7k-runner-no-wire-runtime-isolation-guard.json").read_text())

assert data["stage"] == "7K"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

runner = data["runner"]
assert runner["path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert runner["must_exist"] is True
assert runner["manual_ops_tool_only"] is True
assert runner["runtime_import_allowed"] is False
assert runner["runtime_reference_allowed"] is False
assert runner["frontend_reference_allowed"] is False
assert runner["backend_reference_allowed"] is False
assert runner["gateway_reference_allowed"] is False
assert runner["systemd_reference_allowed"] is False
assert runner["scheduled_execution_allowed"] is False
assert runner["http_endpoint_exposed"] is False

for path in [
    "edge_controller.py",
    "frontend/",
    "backend/",
    "public_gateway.py",
    "ops/systemd/",
]:
    assert path in data["blocked_runtime_locations"]

for pattern in [
    "run-authenticated-shadow-comparison",
    "ops/compare/run-authenticated-shadow-comparison.py",
    "EDGE_AUTH_SHADOW_COMPARE",
    "stage-7j",
    "stage_7j",
    "stage-7k",
    "stage_7k",
]:
    assert pattern in data["blocked_reference_patterns"]

behavior = data["required_runner_behavior"]
assert behavior["offline_default_generates_valid_artifact"] is True
assert behavior["authenticated_execution_requires_explicit_flag"] is True
assert behavior["authenticated_execution_requires_confirmation"] is True
assert behavior["authenticated_execution_fails_closed_without_auth"] is True
assert behavior["auth_values_not_printed"] is True
assert behavior["auth_values_not_stored"] is True

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7K guard JSON is valid")
PY

echo
echo "=== runner must exist and compile ==="
[ -x "$runner" ] && echo "OK: runner exists and is executable" || { echo "FAIL: runner missing or not executable"; fail=1; }

.venv/bin/python -m py_compile "$runner" "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== runner offline mode should still generate a valid artifact ==="
rm -f /tmp/stage7k-study-offline.json /tmp/stage7k-study-offline.out

.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output /tmp/stage7k-study-offline.json \
  > /tmp/stage7k-study-offline.out 2>&1

cat /tmp/stage7k-study-offline.out
python3 "$validator" /tmp/stage7k-study-offline.json

echo
echo "=== authenticated execution should still fail closed without auth ==="
set +e
EDGE_AUTH_SHADOW_COMPARE_BASE_URL="http://127.0.0.1:7070" \
.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --execute-authenticated \
  --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE \
  --output /tmp/stage7k-noauth.json \
  > /tmp/stage7k-noauth.out 2>&1
noauth_code="$?"
set -e

cat /tmp/stage7k-noauth.out

if [ "$noauth_code" -eq 0 ]; then
  echo "FAIL: runner should fail closed without auth"
  fail=1
else
  echo "OK: runner failed closed without auth"
fi

echo
echo "=== runner must not print or store auth env values in offline mode ==="
secret_cookie="session=stage7k_super_secret_cookie_value_1234567890"
rm -f /tmp/stage7k-authenv-offline.json /tmp/stage7k-authenv-offline.out

EDGE_AUTH_SHADOW_COMPARE_COOKIE="$secret_cookie" \
.venv/bin/python "$runner" \
  --domain companion \
  --case companion_chat \
  --output /tmp/stage7k-authenv-offline.json \
  > /tmp/stage7k-authenv-offline.out 2>&1

if grep -R "stage7k_super_secret_cookie_value_1234567890" /tmp/stage7k-authenv-offline.out /tmp/stage7k-authenv-offline.json >/dev/null 2>&1; then
  echo "FAIL: auth value leaked into output or artifact"
  fail=1
else
  echo "OK: auth value not printed or stored"
fi

python3 "$validator" /tmp/stage7k-authenv-offline.json

echo
echo "=== runner references must not appear in blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|ops/compare/run-authenticated-shadow-comparison.py|EDGE_AUTH_SHADOW_COMPARE|stage-7j|stage_7j|stage-7k|stage_7k" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: runner references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: runner references not found in blocked runtime locations"
fi

echo
echo "=== runner must not be imported by runtime modules ==="
runtime_import_hits="$(
  grep -RInE "import .*run.authenticated.shadow|from .*run.authenticated.shadow|ops\.compare|run_authenticated_shadow" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py 2>/dev/null || true
)"

if [ -n "$runtime_import_hits" ]; then
  echo "FAIL: runner import-like references found in runtime locations"
  echo "$runtime_import_hits"
  fail=1
else
  echo "OK: no runner import-like references found in runtime locations"
fi

echo
echo "=== runner must not be referenced by service/scheduler files ==="
systemd_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE|ops/compare" \
    ops/systemd \
    /etc/systemd/system/edge-queue-controller.service.d 2>/dev/null || true
)"

if [ -n "$systemd_hits" ]; then
  echo "FAIL: runner references found in service/scheduler locations"
  echo "$systemd_hits"
  fail=1
else
  echo "OK: runner references not found in service/scheduler locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7k-router-disabled.json \
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
    cat /tmp/stage7k-router-disabled.json || true
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
  echo "PASS: Stage 7K runner no-wire runtime isolation guard smoke passed"
else
  echo "FAIL: Stage 7K runner no-wire runtime isolation guard smoke failed"
fi

exit "$fail"
