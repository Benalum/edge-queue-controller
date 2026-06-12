#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6R Universal Intent Router Study shadow no-wire guard smoke ==="

fail=0

contract="docs/generated/stage-6r-study-shadow-adapter-no-wire-guard.json"
doc="docs/stage-6r-universal-intent-router-study-shadow-no-wire-guard.md"
helper="_stage6q_study_adapter_shadow"

for f in \
  "$contract" \
  "$doc" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6q-universal-intent-router-study-shadow-adapter.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate guard contract json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6r-study-shadow-adapter-no-wire-guard.json").read_text())

assert data["stage"] == "6R"
assert data["runtime_behavior_change"] is False
assert data["helper"] == "_stage6q_study_adapter_shadow"
assert data["helper_allowed_file"] == "edge_intent_router.py"
assert "edge_controller.py" in data["must_not_be_wired_in"]
assert data["required_runtime_state"]["router_dry_run_endpoint_disabled_by_default"] is True
assert data["required_runtime_state"]["expected_disabled_http_code"] == 404

print("OK: Stage 6R no-wire guard contract is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== helper should exist only in helper module/runtime docs/smokes ==="
if grep -q "def $helper" edge_intent_router.py; then
  echo "OK: helper definition exists in edge_intent_router.py"
else
  echo "FAIL: helper definition missing from edge_intent_router.py"
  fail=1
fi

echo
echo "=== helper must not be wired into controller/frontend/backend/gateway/systemd ==="
blocked_hits="$(
  grep -RIn "$helper" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: helper appears in blocked runtime wiring locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: helper not found in blocked runtime wiring locations"
fi

echo
echo "=== endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6r-disabled.json \
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
    cat /tmp/stage6r-disabled.json || true
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
  echo "PASS: Stage 6R Universal Intent Router Study shadow no-wire guard smoke passed"
else
  echo "FAIL: Stage 6R Universal Intent Router Study shadow no-wire guard smoke failed"
fi

exit "$fail"
