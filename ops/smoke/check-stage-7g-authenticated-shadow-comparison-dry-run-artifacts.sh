#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7G authenticated shadow comparison dry-run artifact examples smoke ==="

fail=0

plan="docs/generated/stage-7g-authenticated-shadow-comparison-dry-run-artifacts-plan.json"
doc="docs/stage-7g-authenticated-shadow-comparison-dry-run-artifacts.md"
study_artifact="docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json"
companion_artifact="docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
guardrail="docs/generated/stage-7d-authenticated-test-secret-handling-guardrail.json"
stage7e="docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json"
stage7f="docs/generated/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.json"

for f in \
  "$plan" \
  "$doc" \
  "$study_artifact" \
  "$companion_artifact" \
  "$validator" \
  "$schema" \
  "$guardrail" \
  "$stage7e" \
  "$stage7f" \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7G plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7g-authenticated-shadow-comparison-dry-run-artifacts-plan.json").read_text())

assert data["stage"] == "7G"
assert data["runtime_behavior_change"] is False
assert data["artifact_schema_version"] == "stage-7c-v1"
assert data["validator"] == "ops/validate/validate-authenticated-shadow-comparison-artifact.py"

artifacts = {item["domain"]: item for item in data["example_artifacts"]}
assert set(artifacts) == {"study", "companion"}
assert artifacts["study"]["helper"] == "_stage6q_study_adapter_shadow"
assert artifacts["study"]["expected_intent"] == "study.next"
assert artifacts["study"]["route"] == "/api/study/session/command"
assert artifacts["companion"]["helper"] == "_stage6v_companion_adapter_shadow"
assert artifacts["companion"]["expected_intent"] == "companion.chat"
assert artifacts["companion"]["route"] == "/api/companion/chat"

for limit in [
    "examples do not use real authentication",
    "examples do not call authenticated routes",
    "examples do not store raw route responses",
    "examples do not store cookies, tokens, passwords, or secrets",
    "examples do not enable router dispatch",
    "examples do not enable model calls",
    "examples do not change runtime wiring",
]:
    assert limit in data["example_limits"]

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7G plan JSON is valid")
PY

python3 -m py_compile "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== validate Stage 7G artifacts with Stage 7E validator ==="
python3 "$validator" "$study_artifact" "$companion_artifact"

echo
echo "=== verify artifacts match helper dry-run outputs ==="
.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_intent_router

study = json.loads(Path("docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json").read_text())
companion = json.loads(Path("docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json").read_text())

study_shadow = edge_intent_router._stage6q_study_adapter_shadow({"command": "next"})
study_router = study_shadow["router_result"]

assert study["stage"] == "7G"
assert study["domain"] == "study"
assert study["runtime_behavior_change"] is False
assert study["test_identity"]["real_user_secret_stored"] is False
assert study["current_route_observation"]["raw_response_stored"] is False
assert study["current_route_observation"]["response_class"] == "example_not_executed"
assert study["shadow_observation"]["helper"] == "_stage6q_study_adapter_shadow"
assert study["shadow_observation"]["intent"] == study_router["intent"]["name"]
assert study["shadow_observation"]["rule_id"] == study_router["decision_trace"][-1]["rule_id"]
assert study["shadow_observation"]["model_call_required"] is False
assert study["shadow_observation"]["allowed_to_dispatch"] is False
assert study["shadow_observation"]["dispatch_performed"] is False
assert study["shadow_observation"]["behavior_changed"] is False

companion_shadow = edge_intent_router._stage6v_companion_adapter_shadow({"message": "Can you help me plan my study time?"})
companion_router = companion_shadow["router_result"]

assert companion["stage"] == "7G"
assert companion["domain"] == "companion"
assert companion["runtime_behavior_change"] is False
assert companion["test_identity"]["real_user_secret_stored"] is False
assert companion["current_route_observation"]["raw_response_stored"] is False
assert companion["current_route_observation"]["response_class"] == "example_not_executed"
assert companion["shadow_observation"]["helper"] == "_stage6v_companion_adapter_shadow"
assert companion["shadow_observation"]["intent"] == companion_router["intent"]["name"]
assert companion["shadow_observation"]["rule_id"] == companion_router["decision_trace"][-1]["rule_id"]
assert companion["shadow_observation"]["model_call_required"] is False
assert companion["shadow_observation"]["allowed_to_dispatch"] is False
assert companion["shadow_observation"]["dispatch_performed"] is False
assert companion["shadow_observation"]["behavior_changed"] is False

for artifact in [study, companion]:
    safety = artifact["safety_observation"]
    assert safety["router_endpoint_disabled_by_default"] is True
    assert safety["router_disabled_http_code"] == 404
    assert safety["secrets_stored"] is False
    assert safety["dispatch_enabled"] is False
    assert safety["model_calls_enabled"] is False
    assert safety["runtime_wiring_changed"] is False
    assert artifact["comparison_result"]["user_visible_regression_detected"] is False
    assert artifact["comparison_result"]["safe_to_continue"] is True

print("OK: Stage 7G artifacts match helper dry-run outputs and safety expectations")
PY

echo
echo "=== scan Stage 7G artifacts for secret-like values ==="
python3 - <<'PY'
import re
from pathlib import Path

files = [
    Path("docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json"),
    Path("docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json"),
    Path("docs/stage-7g-authenticated-shadow-comparison-dry-run-artifacts.md"),
]

patterns = {
    "private_key_block": re.compile(r"BEGIN [A-Z ]*PRIVATE KEY"),
    "openai_like_secret": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "github_pat": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "tailscale_key": re.compile(r"\btskey-[A-Za-z0-9_-]{20,}\b"),
    "jwt_like_value": re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "bearer_value": re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
    "cookie_value": re.compile(r"Cookie:\s*\S+", re.IGNORECASE),
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

print("OK: no secret-like values detected in Stage 7G artifacts/docs")
PY

echo
echo "=== verify Stage 7G is not wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "stage-7g|stage_7g|authenticated_shadow_comparison_dry_run_artifact" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7G artifact/example references appear in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7G artifacts not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7g-router-disabled.json \
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
    cat /tmp/stage7g-router-disabled.json || true
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
  echo "PASS: Stage 7G authenticated shadow comparison dry-run artifact examples smoke passed"
else
  echo "FAIL: Stage 7G authenticated shadow comparison dry-run artifact examples smoke failed"
fi

exit "$fail"
