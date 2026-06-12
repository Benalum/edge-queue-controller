#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7H authenticated shadow comparison runner plan smoke ==="

fail=0

plan="docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json"
doc="docs/stage-7h-authenticated-shadow-comparison-runner-plan.md"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
guardrail="docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"
validator_plan="docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json"
validator_guard="docs/generated/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.json"
study_example="docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json"
companion_example="docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
future_runner="ops/compare/run-authenticated-shadow-comparison.py"

for f in \
  "$plan" \
  "$doc" \
  "$schema" \
  "$guardrail" \
  "$validator_plan" \
  "$validator_guard" \
  "$study_example" \
  "$companion_example" \
  "$validator" \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7H runner plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json").read_text())

assert data["stage"] == "7H"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

runner = data["runner_status"]
assert runner["runner_created_in_this_stage"] is False
assert runner["future_runner_path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert runner["runtime_wired"] is False
assert runner["http_endpoint_exposed"] is False
assert runner["frontend_wired"] is False
assert runner["systemd_wired"] is False

assert set(data["allowed_domains"]) == {"study", "companion"}

required_env = {item["name"]: item for item in data["future_runner_inputs"]["required_environment"]}
assert "EDGE_AUTH_SHADOW_COMPARE_BASE_URL" in required_env
assert "EDGE_AUTH_SHADOW_COMPARE_DOMAIN" in required_env
assert required_env["EDGE_AUTH_SHADOW_COMPARE_BASE_URL"]["secret"] is False
assert required_env["EDGE_AUTH_SHADOW_COMPARE_DOMAIN"]["secret"] is False

auth_env = {item["name"]: item for item in data["future_runner_inputs"]["one_of_auth_environment"]}
assert "EDGE_AUTH_SHADOW_COMPARE_COOKIE" in auth_env
assert "EDGE_AUTH_SHADOW_COMPARE_BEARER" in auth_env
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_COOKIE"]["secret"] is True
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_COOKIE"]["may_be_printed"] is False
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_COOKIE"]["may_be_stored_in_artifact"] is False
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_BEARER"]["secret"] is True
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_BEARER"]["may_be_printed"] is False
assert auth_env["EDGE_AUTH_SHADOW_COMPARE_BEARER"]["may_be_stored_in_artifact"] is False

for behavior in [
    "fail closed if base URL is missing",
    "fail closed if domain is missing or unsupported",
    "fail closed if neither cookie nor bearer auth is provided",
    "never print cookie or bearer values",
    "never write cookie or bearer values to disk",
    "never store raw authenticated route responses by default",
    "validate output artifact with Stage 7E validator before success",
]:
    assert behavior in data["future_runner_required_behavior"]

for forbidden in [
    "auth bypass",
    "committing auth values",
    "printing auth values",
    "router dispatch",
    "router model calls",
    "runtime route wiring",
    "frontend behavior changes",
]:
    assert forbidden in data["forbidden_behavior"]

artifact = data["sanitized_artifact_requirements"]
assert artifact["schema_version"] == "stage-7c-v1"
assert artifact["artifact_kind"] == "authenticated_shadow_comparison_result"
assert artifact["test_identity.real_user_secret_stored"] is False
assert artifact["current_route_observation.raw_response_stored"] is False
assert artifact["safety_observation.secrets_stored"] is False
assert artifact["safety_observation.dispatch_enabled"] is False
assert artifact["safety_observation.model_calls_enabled"] is False
assert artifact["safety_observation.runtime_wiring_changed"] is False

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7H runner plan JSON is valid")
PY

echo
echo "=== future runner should not exist yet ==="
if [ -e "$future_runner" ]; then
  echo "FAIL: future runner exists during planning-only Stage 7H: $future_runner"
  fail=1
else
  echo "OK: future runner not created in Stage 7H"
fi

python3 -m py_compile "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== Stage 7G example artifacts should still validate ==="
python3 "$validator" "$study_example" "$companion_example"

echo
echo "=== scan Stage 7H docs for secret-like values ==="
python3 - <<'PY'
import re
from pathlib import Path

files = [
    Path("docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json"),
    Path("docs/stage-7h-authenticated-shadow-comparison-runner-plan.md"),
]

patterns = {
    "private_key_block": re.compile(r"BEGIN [A-Z ]*PRIVATE KEY"),
    "openai_like_secret": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "github_pat": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "tailscale_key": re.compile(r"\btskey-[A-Za-z0-9_-]{20,}\b"),
    "jwt_like_value": re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "bearer_value": re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
    "cookie_value": re.compile(r"Cookie:\s*\S+", re.IGNORECASE)
}

hits = []
for path in files:
    text = path.read_text(errors="replace")
    for name, pattern in patterns.items():
        if pattern.search(text):
            hits.append((str(path), name))

if hits:
    print("FAIL: secret-like values detected")
    for path, name in hits:
        print(f"{path}: {name}")
    raise SystemExit(1)

print("OK: no secret-like values detected in Stage 7H docs")
PY

echo
echo "=== Stage 7H must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "stage-7h|stage_7h|run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7H runner plan references appear in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7H references not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7h-router-disabled.json \
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
    cat /tmp/stage7h-router-disabled.json || true
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
  echo "PASS: Stage 7H authenticated shadow comparison runner plan smoke passed"
else
  echo "FAIL: Stage 7H authenticated shadow comparison runner plan smoke failed"
fi

exit "$fail"
