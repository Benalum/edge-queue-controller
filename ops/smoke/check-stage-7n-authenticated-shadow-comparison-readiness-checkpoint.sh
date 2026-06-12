#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7N authenticated shadow comparison readiness checkpoint smoke ==="

fail=0

checkpoint="docs/generated/stage-7n-authenticated-shadow-comparison-readiness-checkpoint.json"
doc="docs/stage-7n-authenticated-shadow-comparison-readiness-checkpoint.md"
runner="ops/compare/run-authenticated-shadow-comparison.py"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"

required_files=(
  "$checkpoint"
  "$doc"
  "$runner"
  "$validator"
  "docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json"
  "docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json"
  "docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
  "docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json"
  "docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"
  "docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json"
  "docs/generated/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.json"
  "docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json"
  "docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json"
  "docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json"
  "docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json"
  "docs/generated/stage-7j-local-authenticated-runner-offline-implementation-plan.json"
  "docs/generated/stage-7k-runner-no-wire-runtime-isolation-guard.json"
  "docs/generated/stage-7l-runner-artifact-output-no-commit-guard.json"
  "docs/generated/stage-7m-runner-authenticated-execution-manual-runbook.json"
  "docs/stage-7m-runner-authenticated-execution-manual-runbook.md"
  ".gitignore"
  "edge_intent_router.py"
  "edge_controller.py"
)

for f in "${required_files[@]}"
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7N checkpoint json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7n-authenticated-shadow-comparison-readiness-checkpoint.json").read_text())

assert data["stage"] == "7N"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

chain = data["completed_stage_chain"]
for stage in ["7A", "7B", "7C", "7D", "7E", "7F", "7G", "7H", "7I", "7J", "7K", "7L", "7M"]:
    assert any(item.startswith(stage) for item in chain), f"missing {stage}"

status = data["readiness_status"]
assert status["artifact_schema_ready"] is True
assert status["secret_handling_guardrail_ready"] is True
assert status["artifact_validator_ready"] is True
assert status["dry_run_examples_ready"] is True
assert status["manual_runner_ready"] is True
assert status["runner_runtime_isolated"] is True
assert status["runner_outputs_ignored"] is True
assert status["manual_runbook_ready"] is True
assert status["real_authenticated_comparison_executed"] is False

runner = data["manual_runner"]
assert runner["path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert runner["manual_ops_tool_only"] is True
assert runner["offline_by_default"] is True
assert runner["authenticated_execution_requires_explicit_flag"] is True
assert runner["authenticated_execution_requires_confirmation"] is True
assert runner["fails_closed_without_auth"] is True
assert runner["auth_values_may_be_printed"] is False
assert runner["auth_values_may_be_stored"] is False
assert runner["raw_authenticated_response_may_be_stored"] is False

policy = data["safe_output_policy"]
assert "ops/compare/output/" in policy["ignored_output_locations"]
assert "docs/generated/authenticated-shadow-comparison-results/" in policy["ignored_output_locations"]
assert "*.local-auth-shadow.json" in policy["ignored_file_patterns"]
assert "*.auth-shadow-comparison.json" in policy["ignored_file_patterns"]
assert "*.authenticated-shadow-comparison.json" in policy["ignored_file_patterns"]

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7N checkpoint JSON is valid")
PY

.venv/bin/python -m py_compile "$runner" "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== validate Stage 7C and Stage 7G artifacts with Stage 7E validator ==="
python3 "$validator" \
  docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json \
  docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json \
  docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json

echo
echo "=== runner offline mode should still generate valid ignored artifacts ==="
study_output="ops/compare/output/stage7n-study-readiness.local-auth-shadow.json"
companion_output="ops/compare/output/stage7n-companion-readiness.local-auth-shadow.json"
rm -f "$study_output" "$companion_output" /tmp/stage7n-study.out /tmp/stage7n-companion.out

.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output "$study_output" \
  > /tmp/stage7n-study.out 2>&1

cat /tmp/stage7n-study.out
python3 "$validator" "$study_output"

.venv/bin/python "$runner" \
  --domain companion \
  --case companion_chat \
  --output "$companion_output" \
  > /tmp/stage7n-companion.out 2>&1

cat /tmp/stage7n-companion.out
python3 "$validator" "$companion_output"

for path in "$study_output" "$companion_output"
do
  if git check-ignore -q "$path"; then
    echo "OK: ignored runner output confirmed: $path"
  else
    echo "FAIL: runner output is not ignored: $path"
    fail=1
  fi

  if [ -z "$(git status --short "$path")" ]; then
    echo "OK: runner output does not appear in normal git status: $path"
  else
    echo "FAIL: runner output appears in normal git status: $path"
    git status --short "$path"
    fail=1
  fi
done

echo
echo "=== authenticated execution should still fail closed without auth ==="
set +e
EDGE_AUTH_SHADOW_COMPARE_BASE_URL="http://127.0.0.1:7070" \
.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --execute-authenticated \
  --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE \
  --output ops/compare/output/stage7n-noauth.local-auth-shadow.json \
  > /tmp/stage7n-noauth.out 2>&1
noauth_code="$?"
set -e

cat /tmp/stage7n-noauth.out

if [ "$noauth_code" -eq 0 ]; then
  echo "FAIL: runner should fail closed without auth"
  fail=1
else
  echo "OK: runner failed closed without auth"
fi

echo
echo "=== runner must not print or store auth env values in offline mode ==="
secret_cookie="session=stage7n_super_secret_cookie_value_1234567890"
auth_output="ops/compare/output/stage7n-authenv.local-auth-shadow.json"
rm -f "$auth_output" /tmp/stage7n-authenv.out

EDGE_AUTH_SHADOW_COMPARE_COOKIE="$secret_cookie" \
.venv/bin/python "$runner" \
  --domain companion \
  --case companion_chat \
  --output "$auth_output" \
  > /tmp/stage7n-authenv.out 2>&1

if grep -R "stage7n_super_secret_cookie_value_1234567890" /tmp/stage7n-authenv.out "$auth_output" >/dev/null 2>&1; then
  echo "FAIL: auth value leaked into output or artifact"
  fail=1
else
  echo "OK: auth value not printed or stored"
fi

python3 "$validator" "$auth_output"

echo
echo "=== Stage 7M runbook should avoid nested markdown code fences ==="
if grep -F '```' docs/stage-7m-runner-authenticated-execution-manual-runbook.md >/dev/null; then
  echo "FAIL: Stage 7M runbook contains markdown fences that can break heredoc copy/paste"
  fail=1
else
  echo "OK: Stage 7M runbook avoids markdown fences"
fi

echo
echo "=== Stage 7N must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "stage-7n|stage_7n|authenticated-shadow-comparison-readiness-checkpoint" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7N references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7N references not found in blocked runtime locations"
fi

echo
echo "=== runner references must remain absent from service/scheduler files ==="
systemd_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE|local-auth-shadow|auth-shadow-comparison" \
    ops/systemd \
    /etc/systemd/system/edge-queue-controller.service.d 2>/dev/null || true
)"

if [ -n "$systemd_hits" ]; then
  echo "FAIL: runner/checkpoint references found in service/scheduler locations"
  echo "$systemd_hits"
  fail=1
else
  echo "OK: runner/checkpoint references not found in service/scheduler locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7n-router-disabled.json \
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
    cat /tmp/stage7n-router-disabled.json || true
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
  echo "PASS: Stage 7N authenticated shadow comparison readiness checkpoint smoke passed"
else
  echo "FAIL: Stage 7N authenticated shadow comparison readiness checkpoint smoke failed"
fi

exit "$fail"
