#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7E authenticated shadow comparison artifact validator smoke ==="

fail=0

plan="docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json"
doc="docs/stage-7e-authenticated-shadow-comparison-artifact-validator.md"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
example="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json"
guardrail="docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"

for f in \
  "$plan" \
  "$doc" \
  "$validator" \
  "$schema" \
  "$example" \
  "$guardrail" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-7c-authenticated-shadow-comparison-artifact-schema.md \
  docs/stage-7d-authenticated-test-secret-handling-guardrail.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7E plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json").read_text())

assert data["stage"] == "7E"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

validator = data["validator"]
assert validator["path"] == "ops/validate/validate-authenticated-shadow-comparison-artifact.py"
assert validator["runtime_wired"] is False
assert validator["http_endpoint_exposed"] is False
assert validator["frontend_wired"] is False
assert validator["systemd_wired"] is False

prereq = data["prerequisites"]
assert prereq["stage_6z_complete"] is True
assert prereq["stage_7a_complete"] is True
assert prereq["stage_7b_complete"] is True
assert prereq["stage_7c_complete"] is True
assert prereq["stage_7d_complete"] is True
assert prereq["artifact_schema_version"] == "stage-7c-v1"

for requirement in [
    "validate required top-level fields",
    "validate supported domain",
    "validate route allowed for domain",
    "validate shadow helper allowed for domain",
    "validate safe intent allowed for domain",
    "reject secret-like values",
    "reject dispatch enabled",
    "reject model calls enabled",
    "reject runtime wiring changed",
]:
    assert requirement in data["validator_requirements"]

print("OK: Stage 7E validator plan JSON is valid")
PY

python3 -m py_compile "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== validator should accept Stage 7C example ==="
python3 "$validator" "$example"

echo
echo "=== create temporary valid Companion artifact ==="
python3 - <<'PY'
import json
from pathlib import Path

artifact = {
    "schema_version": "stage-7c-v1",
    "artifact_kind": "authenticated_shadow_comparison_result",
    "stage": "future-stage",
    "domain": "companion",
    "runtime_behavior_change": False,
    "comparison_mode": "authenticated_shadow_comparison_without_dispatch",
    "test_identity": {
        "label": "normal_test_user",
        "real_user_secret_stored": False,
        "auth_method_summary": "authenticated session used locally but not stored"
    },
    "current_route_observation": {
        "route": "/api/companion/chat",
        "method": "POST",
        "http_status": 200,
        "response_class": "existing_route_response",
        "state_change_summary": "summarized only",
        "raw_response_stored": False
    },
    "shadow_observation": {
        "helper": "_stage6v_companion_adapter_shadow",
        "intent": "companion.chat",
        "confidence_band": "high",
        "existing_route": "/api/companion/chat",
        "rule_id": "companion.chat.text",
        "source_surface_policy_allowed": True,
        "model_call_required": False,
        "allowed_to_dispatch": False,
        "dispatch_performed": False,
        "behavior_changed": False
    },
    "safety_observation": {
        "router_endpoint_disabled_by_default": True,
        "router_disabled_http_code": 404,
        "secrets_stored": False,
        "dispatch_enabled": False,
        "model_calls_enabled": False,
        "runtime_wiring_changed": False
    },
    "comparison_result": {
        "passed": True,
        "intent_matches_expected": True,
        "user_visible_regression_detected": False,
        "safe_to_continue": True
    },
    "notes": [
        "Temporary smoke artifact.",
        "No raw secrets or personal content stored."
    ]
}

Path("/tmp/stage7e-valid-companion-artifact.json").write_text(json.dumps(artifact, indent=2) + "\n")
print("OK: wrote /tmp/stage7e-valid-companion-artifact.json")
PY

python3 "$validator" /tmp/stage7e-valid-companion-artifact.json

echo
echo "=== validator should reject dispatch/model-call unsafe artifact ==="
python3 - <<'PY'
import json
from pathlib import Path

artifact = json.loads(Path("/tmp/stage7e-valid-companion-artifact.json").read_text())
artifact["shadow_observation"]["dispatch_performed"] = True
artifact["shadow_observation"]["allowed_to_dispatch"] = True
artifact["safety_observation"]["dispatch_enabled"] = True
Path("/tmp/stage7e-invalid-dispatch-artifact.json").write_text(json.dumps(artifact, indent=2) + "\n")
print("OK: wrote /tmp/stage7e-invalid-dispatch-artifact.json")
PY

if python3 "$validator" /tmp/stage7e-invalid-dispatch-artifact.json; then
  echo "FAIL: validator accepted unsafe dispatch artifact"
  fail=1
else
  echo "OK: validator rejected unsafe dispatch artifact"
fi

echo
echo "=== validator should reject secret-like artifact ==="
python3 - <<'PY'
import json
from pathlib import Path

artifact = json.loads(Path("/tmp/stage7e-valid-companion-artifact.json").read_text())
artifact["notes"] = ["temporary test secret " + "sk-" + ("A" * 24)]
Path("/tmp/stage7e-invalid-secret-artifact.json").write_text(json.dumps(artifact, indent=2) + "\n")
print("OK: wrote /tmp/stage7e-invalid-secret-artifact.json")
PY

if python3 "$validator" /tmp/stage7e-invalid-secret-artifact.json; then
  echo "FAIL: validator accepted secret-like artifact"
  fail=1
else
  echo "OK: validator rejected secret-like artifact"
fi

echo
echo "=== verify validator is not wired into runtime locations ==="
if grep -RIn "validate-authenticated-shadow-comparison-artifact.py\|authenticated_shadow_comparison_artifact_validator" \
  edge_controller.py frontend backend public_gateway.py ops/systemd 2>/dev/null; then
  echo "FAIL: validator appears in blocked runtime locations"
  fail=1
else
  echo "OK: validator not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7e-router-disabled.json \
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
    cat /tmp/stage7e-router-disabled.json || true
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
  echo "PASS: Stage 7E authenticated shadow comparison artifact validator smoke passed"
else
  echo "FAIL: Stage 7E authenticated shadow comparison artifact validator smoke failed"
fi

exit "$fail"
