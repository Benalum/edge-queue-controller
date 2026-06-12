#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6T Universal Intent Router Study shadow HTTP probe plan smoke ==="

fail=0

plan="docs/generated/stage-6t-study-shadow-http-probe-plan.json"
doc="docs/stage-6t-universal-intent-router-study-shadow-http-probe-plan.md"
baseline="docs/generated/stage-6s-study-route-baseline.json"
classification="docs/generated/stage-6d-route-classification.tsv"
helper="_stage6q_study_adapter_shadow"

for f in \
  "$plan" \
  "$doc" \
  "$baseline" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6s-universal-intent-router-study-route-baseline.md \
  docs/stage-6r-universal-intent-router-study-shadow-no-wire-guard.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 6T plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6t-study-shadow-http-probe-plan.json").read_text())

assert data["stage"] == "6T"
assert data["runtime_behavior_change"] is False
assert data["baseline_from"] == "Stage 6S"
assert data["current_unauthenticated_baseline"]["expected_study_http_code"] == 401
assert "/api/study/intent/parse" in data["current_unauthenticated_baseline"]["routes"]
assert "/api/study/session/command" in data["current_unauthenticated_baseline"]["routes"]

router_state = data["router_required_state"]
assert router_state["dry_run_endpoint_disabled_by_default"] is True
assert router_state["expected_router_disabled_http_code"] == 404
assert router_state["dispatch_enabled"] is False
assert router_state["model_calls_enabled"] is False

for required in [
    "do not wire router into Study routes",
    "do not bypass auth",
    "do not enable dispatch",
    "do not enable model calls",
]:
    assert required in data["must_not_do"]

print("OK: Stage 6T plan JSON is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

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
echo "=== verify Study shadow adapter remains isolated ==="
if grep -q "def $helper" edge_intent_router.py; then
  echo "OK: helper exists in edge_intent_router.py"
else
  echo "FAIL: helper missing from edge_intent_router.py"
  fail=1
fi

blocked_hits="$(
  grep -RIn "$helper" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: helper appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: helper not wired into blocked runtime locations"
fi

echo
echo "=== live unauthenticated Study route baseline ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  for route in \
    "/api/study/intent/parse" \
    "/api/study/session/command"
  do
    out="/tmp/stage6t$(echo "$route" | tr '/' '_').json"
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
      echo "FAIL: expected Study route to return 401 before router wiring: $route"
      cat "$out" || true
      fail=1
    fi
  done
else
  echo "WARN: controller inactive; skipped live unauthenticated Study route baseline"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6t-router-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "router_disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: router endpoint remains disabled by default"
  else
    echo "FAIL: router endpoint should still be disabled by default"
    cat /tmp/stage6t-router-disabled.json || true
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
  echo "PASS: Stage 6T Universal Intent Router Study shadow HTTP probe plan smoke passed"
else
  echo "FAIL: Stage 6T Universal Intent Router Study shadow HTTP probe plan smoke failed"
fi

exit "$fail"
