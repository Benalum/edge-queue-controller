#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6H Universal Intent Router fixture set smoke ==="

fail=0

fixtures="docs/generated/stage-6h-router-fixtures.json"
doc6h="docs/stage-6h-universal-intent-router-fixture-set.md"

for f in \
  edge_controller.py \
  "$fixtures" \
  "$doc6h" \
  docs/stage-6f-universal-intent-router-disabled-dry-run-endpoint.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate fixture json ==="
python3 -m json.tool "$fixtures" >/dev/null
echo "OK: fixture JSON is valid"

echo
echo "=== run fixture expectations through helper ==="
.venv/bin/python - <<'PY'
import json
from pathlib import Path
import edge_controller

fixtures = json.loads(Path("docs/generated/stage-6h-router-fixtures.json").read_text())

if len(fixtures) < 7:
    raise SystemExit(f"expected at least 7 fixtures, got {len(fixtures)}")

for item in fixtures:
    name = item["name"]
    body = item["body"]
    expect = item["expect"]

    result = edge_controller._stage6f_router_response(body)

    assert result["ok"] is True, name
    assert result["dry_run"] is True, name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name

    assert result["intent"]["name"] == expect["intent"], (name, result["intent"]["name"], expect["intent"])
    assert result["language"]["detected"] == expect["language"], (name, result["language"]["detected"], expect["language"])
    assert result["target"]["existing_route"] == expect["route"], (name, result["target"]["existing_route"], expect["route"])
    assert result["model_routing"]["tier"] == expect["tier"], (name, result["model_routing"]["tier"], expect["tier"])

    print(f"OK: {name} -> {expect['intent']}")

print("OK: all Stage 6H fixtures passed")
PY

echo
echo "=== endpoint must still be disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6h-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: endpoint remains disabled by default"
  else
    echo "FAIL: endpoint should still be disabled by default"
    cat /tmp/stage6h-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

echo
echo "=== no runtime files should be modified in Stage 6H ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6H Universal Intent Router fixture set smoke passed"
else
  echo "FAIL: Stage 6H Universal Intent Router fixture set smoke failed"
fi

exit "$fail"
