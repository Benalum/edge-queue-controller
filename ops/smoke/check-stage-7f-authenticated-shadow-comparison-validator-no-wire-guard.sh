#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7F authenticated shadow comparison validator no-wire guard smoke ==="

fail=0

guard="docs/generated/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.json"
doc="docs/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.md"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
example="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json"
stage7e="docs/generated/stage-7e-authenticated-shadow-comparison-artifact-validator-plan.json"

for f in \
  "$guard" \
  "$doc" \
  "$validator" \
  "$schema" \
  "$example" \
  "$stage7e" \
  edge_controller.py \
  edge_intent_router.py \
  docs/stage-7e-authenticated-shadow-comparison-artifact-validator.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7F guard json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7f-authenticated-shadow-comparison-validator-no-wire-guard.json").read_text())

assert data["stage"] == "7F"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

validator = data["validator"]
assert validator["path"] == "ops/validate/validate-authenticated-shadow-comparison-artifact.py"
assert validator["allowed_location"] == "ops/validate/"
assert validator["runtime_wired"] is False
assert validator["http_endpoint_exposed"] is False
assert validator["frontend_wired"] is False
assert validator["backend_wired"] is False
assert validator["gateway_wired"] is False
assert validator["systemd_wired"] is False

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False

for blocked in [
    "edge_controller.py",
    "frontend/",
    "backend/",
    "public_gateway.py",
    "ops/systemd/"
]:
    assert blocked in data["must_not_be_referenced_from"]

print("OK: Stage 7F guard JSON is valid")
PY

python3 -m py_compile "$validator" edge_controller.py edge_intent_router.py

echo
echo "=== validator should still accept Stage 7C example ==="
python3 "$validator" "$example"

echo
echo "=== validator must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "validate-authenticated-shadow-comparison-artifact.py|authenticated_shadow_comparison_artifact_validator|stage-7e-authenticated-shadow-comparison-artifact-validator" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: validator appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: validator not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7f-router-disabled.json \
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
    cat /tmp/stage7f-router-disabled.json || true
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
  echo "PASS: Stage 7F authenticated shadow comparison validator no-wire guard smoke passed"
else
  echo "FAIL: Stage 7F authenticated shadow comparison validator no-wire guard smoke failed"
fi

exit "$fail"
