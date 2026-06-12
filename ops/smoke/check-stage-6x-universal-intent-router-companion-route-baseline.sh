#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6X Universal Intent Router Companion route baseline smoke ==="

fail=0

baseline="docs/generated/stage-6x-companion-route-baseline.json"
doc="docs/stage-6x-universal-intent-router-companion-route-baseline.md"
classification="docs/generated/stage-6d-route-classification.tsv"
helper="_stage6v_companion_adapter_shadow"

for f in \
  "$baseline" \
  "$doc" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6u-universal-intent-router-companion-adapter-plan.md \
  docs/stage-6v-universal-intent-router-companion-shadow-adapter.md \
  docs/stage-6w-universal-intent-router-companion-shadow-no-wire-guard.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate baseline json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6x-companion-route-baseline.json").read_text())

assert data["stage"] == "6X"
assert data["runtime_behavior_change"] is False

routes = {item["route"] for item in data["companion_routes"]}
assert "/api/companion/chat" in routes
assert "/api/chat/queued" in routes

probe = data["live_probe_policy"]
assert probe["probe_type"] == "unauthenticated_non_mutating_empty_json"
assert probe["record_http_code"] is True
for code in [404, 500, 502, 503, 504]:
    assert code in probe["must_not_return"]

router_state = data["router_state_required"]
assert router_state["dry_run_endpoint_disabled_by_default"] is True
assert router_state["expected_disabled_http_code"] == 404
assert router_state["dispatch_enabled"] is False
assert router_state["model_calls_enabled"] is False

shadow = data["shadow_adapter_state_required"]
assert shadow["helper_exists"] is True
assert shadow["helper_wired_into_runtime"] is False
assert shadow["helper_allowed_file"] == "edge_intent_router.py"
assert shadow["helper_name"] == "_stage6v_companion_adapter_shadow"

print("OK: Stage 6X baseline JSON is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify Companion/Chat routes are still classified ==="
for route in \
  "/api/companion/chat" \
  "/api/chat/queued"
do
  if grep -q "$route" "$classification"; then
    echo "OK: route present in classification: $route"
  else
    echo "FAIL: route missing from classification: $route"
    fail=1
  fi
done

echo
echo "=== verify Companion shadow adapter is still not wired into runtime ==="
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
echo "=== optional live Companion/Chat route probe, non-mutating baseline only ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  for route in \
    "/api/companion/chat" \
    "/api/chat/queued"
  do
    out="/tmp/stage6x$(echo "$route" | tr '/' '_').json"
    code="$(
      curl -sS -o "$out" \
        -w "%{http_code}" \
        -X POST "http://127.0.0.1:7070$route" \
        -H 'Content-Type: application/json' \
        --data '{}' || true
    )"
    echo "companion_route_probe route=$route http_code=$code"

    case "$code" in
      404|500|502|503|504)
        echo "FAIL: unexpected baseline code for Companion/Chat route: $route code=$code"
        cat "$out" || true
        fail=1
        ;;
      *)
        echo "OK: route responded with existing non-404/non-5xx behavior: $route code=$code"
        ;;
    esac
  done
else
  echo "WARN: controller inactive; skipped optional live Companion/Chat route probe"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6x-router-disabled.json \
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
    cat /tmp/stage6x-router-disabled.json || true
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
  echo "PASS: Stage 6X Universal Intent Router Companion route baseline smoke passed"
else
  echo "FAIL: Stage 6X Universal Intent Router Companion route baseline smoke failed"
fi

exit "$fail"
