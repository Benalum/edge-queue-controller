#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7D authenticated test identity secret-handling guardrail smoke ==="

fail=0

guardrail="docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"
doc="docs/stage-7d-authenticated-test-secret-handling-guardrail.md"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
example="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json"
stage7a="docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json"
stage7b="docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json"
foundation="docs/generated/stage-6z-universal-intent-router-foundation-summary.json"

for f in \
  "$guardrail" \
  "$doc" \
  "$schema" \
  "$example" \
  "$stage7a" \
  "$stage7b" \
  "$foundation" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-7c-authenticated-shadow-comparison-artifact-schema.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7D guardrail json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json").read_text())

assert data["stage"] == "7D"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

prereq = data["prerequisites"]
assert prereq["stage_6z_complete"] is True
assert prereq["stage_7a_complete"] is True
assert prereq["stage_7b_complete"] is True
assert prereq["stage_7c_complete"] is True
assert prereq["artifact_schema_version"] == "stage-7c-v1"

allowed_methods = {item["method"]: item for item in data["allowed_auth_handling"]}
assert "manual_ephemeral_authenticated_session" in allowed_methods
assert "runtime_only_environment_variable" in allowed_methods
assert "local_test_user_label" in allowed_methods
assert allowed_methods["manual_ephemeral_authenticated_session"]["storage_allowed"] is False
assert allowed_methods["runtime_only_environment_variable"]["storage_allowed"] is False
assert allowed_methods["runtime_only_environment_variable"]["printing_allowed"] is False

for forbidden in [
    "real user passwords",
    "session cookies",
    "bearer tokens",
    "Cloudflare Access tokens",
    "Tailscale auth keys",
    "SSH private keys",
    "API keys",
    "database credentials",
]:
    assert forbidden in data["forbidden_repository_content"]

redaction = data["artifact_redaction_requirements"]
assert redaction["test_identity.real_user_secret_stored"] is False
assert redaction["current_route_observation.raw_response_stored"] is False
assert redaction["safety_observation.secrets_stored"] is False

for rule in [
    "do not print authentication values",
    "do not write authentication values to files",
    "do not commit authentication values",
    "fail closed if an expected authentication value is missing",
    "fail closed if a secret-like value is detected in a planned artifact",
]:
    assert rule in data["future_test_runner_rules"]

for key in [
    "runtime_behavior_change",
    "router_dispatch_enabled",
    "router_model_calls_enabled",
    "runtime_wiring_changed",
    "secrets_stored",
]:
    assert key in data["must_remain_false"]

print("OK: Stage 7D guardrail JSON is valid")
PY

echo
echo "=== validate Stage 7C artifact schema still enforces no-secret artifact values ==="
python3 - <<'PY'
import json
from pathlib import Path

schema = json.loads(Path("docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json").read_text())
example = json.loads(Path("docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json").read_text())

assert schema["schema_version"] == "stage-7c-v1"
assert example["schema_version"] == "stage-7c-v1"
assert example["test_identity"]["real_user_secret_stored"] is False
assert example["current_route_observation"]["raw_response_stored"] is False
assert example["safety_observation"]["secrets_stored"] is False
assert example["safety_observation"]["dispatch_enabled"] is False
assert example["safety_observation"]["model_calls_enabled"] is False
assert example["safety_observation"]["runtime_wiring_changed"] is False

for invariant in [
    "no real user secrets stored",
    "no router dispatch",
    "no router model calls",
    "no runtime route wiring changes",
    "no auth bypass",
]:
    assert invariant in schema["global_safety_invariants"]

print("OK: Stage 7C schema/example align with Stage 7D guardrail")
PY

echo
echo "=== scan Stage 7D docs for accidentally embedded secret-like values ==="
python3 - <<'PY'
import re
from pathlib import Path

files = [
    Path("docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"),
    Path("docs/stage-7d-authenticated-test-secret-handling-guardrail.md"),
]

patterns = {
    "private_key_block": re.compile(r"BEGIN [A-Z ]*PRIVATE KEY"),
    "openai_like_secret": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "github_pat": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "slack_token": re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    "tailscale_key": re.compile(r"\btskey-[A-Za-z0-9_-]{20,}\b"),
    "aws_access_key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "jwt_like_value": re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "bearer_value": re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
    "cookie_value": re.compile(r"Cookie:\s*\S+", re.IGNORECASE),
    "session_assignment": re.compile(r"\b(session|sessionid|token|auth_token)=\S+", re.IGNORECASE),
}

hits = []
for path in files:
    text = path.read_text(errors="replace")
    for name, pattern in patterns.items():
        for match in pattern.finditer(text):
            hits.append((str(path), name, match.group(0)[:80]))

if hits:
    print("FAIL: secret-like values detected")
    for path, name, sample in hits:
        print(f"{path}: {name}: {sample}")
    raise SystemExit(1)

print("OK: no secret-like values detected in Stage 7D docs")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify router endpoint remains disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7d-router-disabled.json \
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
    cat /tmp/stage7d-router-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped router disabled check"
fi

echo
echo "=== no runtime/systemd files should be modified ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 7D authenticated test identity secret-handling guardrail smoke passed"
else
  echo "FAIL: Stage 7D authenticated test identity secret-handling guardrail smoke failed"
fi

exit "$fail"
