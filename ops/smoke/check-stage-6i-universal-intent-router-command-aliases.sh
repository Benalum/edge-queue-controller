#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6I Universal Intent Router command aliases smoke ==="

fail=0
fixtures="docs/generated/stage-6i-router-alias-fixtures.json"

for f in \
  edge_controller.py \
  "$fixtures" \
  docs/stage-6i-universal-intent-router-command-aliases.md \
  docs/stage-6h-universal-intent-router-fixture-set.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m json.tool "$fixtures" >/dev/null
python3 -m py_compile edge_controller.py

.venv/bin/python - <<'PY'
import json
from pathlib import Path
import edge_controller

fixtures = json.loads(Path("docs/generated/stage-6i-router-alias-fixtures.json").read_text())

for item in fixtures:
    name = item["name"]
    result = edge_controller._stage6f_router_response(item["body"])
    expect = item["expect"]

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

print("OK: all Stage 6I alias fixtures passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6i-disabled.json \
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
    cat /tmp/stage6i-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6I Universal Intent Router command aliases smoke passed"
else
  echo "FAIL: Stage 6I Universal Intent Router command aliases smoke failed"
fi

exit "$fail"
