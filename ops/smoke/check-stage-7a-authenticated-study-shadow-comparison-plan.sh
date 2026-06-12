#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7A authenticated Study shadow comparison plan smoke ==="

fail=0

plan="docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json"
doc="docs/stage-7a-authenticated-study-shadow-comparison-plan.md"
foundation="docs/generated/stage-6z-universal-intent-router-foundation-summary.json"
classification="docs/generated/stage-6d-route-classification.tsv"
study_helper="_stage6q_study_adapter_shadow"

for f in \
  "$plan" \
  "$doc" \
  "$foundation" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6z-universal-intent-router-foundation-completion.md \
  docs/stage-6q-universal-intent-router-study-shadow-adapter.md \
  docs/stage-6r-universal-intent-router-study-shadow-no-wire-guard.md \
  docs/stage-6s-universal-intent-router-study-route-baseline.md \
  docs/stage-6t-universal-intent-router-study-shadow-http-probe-plan.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7A plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json").read_text())

assert data["stage"] == "7A"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_planning"

foundation = data["foundation_required"]
assert foundation["stage_6z_complete"] is True
assert foundation["router_foundation_status"] == "ready_for_next_phase"
assert foundation["router_endpoint_disabled_by_default"] is True
assert foundation["expected_router_disabled_http_code"] == 404
assert foundation["study_shadow_helper"] == "_stage6q_study_adapter_shadow"
assert foundation["study_shadow_helper_wired_into_runtime"] is False

routes = {item["route"] for item in data["study_routes_under_comparison"]}
assert "/api/study/intent/parse" in routes
assert "/api/study/session/command" in routes

expected_intents = {item["expected_shadow_intent"] for item in data["future_authenticated_inputs"]}
for intent in ["study.next", "study.skip", "study.hint", "study.answer"]:
    assert intent in expected_intents

for rule in [
    "do not bypass authentication",
    "do not store real user secrets in docs or fixtures",
    "do not enable router dispatch",
    "do not enable router model calls",
    "do not wire the Study shadow helper into edge_controller.py",
]:
    assert rule in data["safety_rules"]

print("OK: Stage 7A plan JSON is valid")
PY

echo
echo "=== validate Stage 6Z foundation summary is ready ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6z-universal-intent-router-foundation-summary.json").read_text())

assert data["stage"] == "6Z"
assert data["foundation_status"] == "ready_for_next_phase"
assert data["required_current_state"]["router_endpoint_disabled_by_default"] is True
assert data["required_current_state"]["expected_router_disabled_http_code"] == 404
assert data["required_current_state"]["dispatch_enabled"] is False
assert data["required_current_state"]["model_calls_enabled"] is False
assert data["required_current_state"]["study_shadow_helper_exists"] is True
assert data["required_current_state"]["shadow_helpers_wired_into_runtime"] is False

print("OK: Stage 6Z foundation summary supports Stage 7A")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify Study helper exists and remains isolated ==="
if grep -q "def $study_helper" edge_intent_router.py; then
  echo "OK: helper exists in edge_intent_router.py: $study_helper"
else
  echo "FAIL: helper missing from edge_intent_router.py: $study_helper"
  fail=1
fi

blocked_hits="$(
  grep -RIn "$study_helper" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Study helper appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Study helper not wired into blocked runtime locations"
fi

echo
echo "=== verify Study routes remain classified ==="
for route in \
  "/api/study/intent/parse" \
  "/api/study/session/command"
do
  if grep -q "$route" "$classification"; then
    echo "OK: route present in classification: $route"
  else
    echo "FAIL: route missing from classification: $route"
    fail=1
  fi
done

echo
echo "=== verify unauthenticated Study routes remain auth-protected ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  for route in \
    "/api/study/intent/parse" \
    "/api/study/session/command"
  do
    out="/tmp/stage7a$(echo "$route" | tr '/' '_').json"
    code="$(
      curl -sS -o "$out" \
        -w "%{http_code}" \
        -X POST "http://127.0.0.1:7070$route" \
        -H 'Content-Type: application/json' \
        --data '{}' || true
    )"

    echo "study_unauth_probe route=$route http_code=$code"

    if [ "$code" = "401" ]; then
      echo "OK: Study route remains auth-protected: $route"
    else
      echo "FAIL: expected Study route to remain auth-protected with 401: $route"
      cat "$out" || true
      fail=1
    fi
  done
else
  echo "WARN: controller inactive; skipped unauthenticated Study route check"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7a-router-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "router_disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: router endpoint remains disabled by default"
  else
    echo "FAIL: router endpoint should still be disabled by default"
    cat /tmp/stage7a-router-disabled.json || true
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
  echo "PASS: Stage 7A authenticated Study shadow comparison plan smoke passed"
else
  echo "FAIL: Stage 7A authenticated Study shadow comparison plan smoke failed"
fi

exit "$fail"
