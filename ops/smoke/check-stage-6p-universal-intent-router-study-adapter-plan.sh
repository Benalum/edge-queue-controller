#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6P Universal Intent Router Study adapter plan smoke ==="

fail=0

plan="docs/generated/stage-6p-study-router-adapter-plan.json"
doc="docs/stage-6p-universal-intent-router-study-adapter-plan.md"
classification="docs/generated/stage-6d-route-classification.tsv"

for f in \
  "$plan" \
  "$doc" \
  "$classification" \
  docs/stage-6n-universal-intent-router-response-schema.md \
  docs/stage-6o-universal-intent-router-http-enabled-schema-smoke.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

p = Path("docs/generated/stage-6p-study-router-adapter-plan.json")
data = json.loads(p.read_text())

assert data["stage"] == "6P"
assert data["runtime_behavior_change"] is False
assert data["adapter_scope"] == "study_only"

routes = {item["route"] for item in data["current_routes"]}
assert "/api/study/intent/parse" in routes
assert "/api/study/session/command" in routes

intents = set(data["initial_supported_intents"])
for intent in ["study.next", "study.skip", "study.hint", "study.answer"]:
    assert intent in intents

for invariant in [
    "never dispatch during Stage 6P",
    "never call a model during Stage 6P",
    "preserve existing Study behavior",
]:
    assert invariant in data["safety_invariants"]

print("OK: Stage 6P JSON plan is valid")
PY

echo
echo "=== verify Study routes are still known router candidates ==="
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
echo "=== required doc markers ==="
for marker in \
  "This stage is docs-only" \
  "This stage does not change runtime behavior" \
  "Current Study router candidates" \
  "Adapter boundary" \
  "Never route through Study adapter" \
  "Stage 6P does not wire the router into Study" \
  "Stage 6P does not enable dispatch" \
  "Stage 6P does not call a model"
do
  if grep -q "$marker" "$doc"; then
    echo "OK: marker: $marker"
  else
    echo "FAIL: missing marker: $marker"
    fail=1
  fi
done

echo
echo "=== endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6p-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: endpoint remains disabled by default"
  else
    echo "FAIL: endpoint should still be disabled by default"
    cat /tmp/stage6p-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
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
  echo "PASS: Stage 6P Universal Intent Router Study adapter plan smoke passed"
else
  echo "FAIL: Stage 6P Universal Intent Router Study adapter plan smoke failed"
fi

exit "$fail"
