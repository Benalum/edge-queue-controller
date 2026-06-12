#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6K Universal Intent Router decision trace smoke ==="

fail=0

for f in \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6k-universal-intent-router-decision-trace.md \
  docs/generated/stage-6h-router-fixtures.json \
  docs/generated/stage-6i-router-alias-fixtures.json
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m py_compile edge_intent_router.py edge_controller.py

grep -q '"decision_trace": decision_trace' edge_intent_router.py && echo "OK: decision_trace returned" || { echo "FAIL: decision_trace missing"; fail=1; }
grep -q 'rule_id = "study.next.alias"' edge_intent_router.py && echo "OK: study next rule id present" || { echo "FAIL: study next rule id missing"; fail=1; }

.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_controller
import edge_intent_router

assert edge_controller._stage6f_router_response is edge_intent_router._stage6f_router_response

fixture_files = [
    Path("docs/generated/stage-6h-router-fixtures.json"),
    Path("docs/generated/stage-6i-router-alias-fixtures.json"),
]

for fixture_file in fixture_files:
    fixtures = json.loads(fixture_file.read_text())

    for item in fixtures:
        name = item["name"]
        result = edge_controller._stage6f_router_response(item["body"])
        expect = item["expect"]

        assert result["ok"] is True, name
        assert result["dry_run"] is True, name
        assert result["dispatch_performed"] is False, name
        assert result["model_routing"]["model_call_required"] is False, name
        assert result["safety"]["allowed_to_dispatch"] is False, name
        assert result["intent"]["name"] == expect["intent"], name
        assert result["language"]["detected"] == expect["language"], name
        assert result["target"]["existing_route"] == expect["route"], name
        assert result["model_routing"]["tier"] == expect["tier"], name

        trace = result.get("decision_trace")
        assert isinstance(trace, list) and len(trace) >= 2, name
        assert trace[0]["step"] == "normalize_input", name
        assert trace[-1]["step"] == "rule_result", name
        assert trace[-1]["intent"] == expect["intent"], name
        assert trace[-1]["dispatch_blocked_reason"] == "dry_run_endpoint_never_dispatches", name

        print(f"OK: {fixture_file.name}: {name} trace -> {trace[-1]['rule_id']}")

print("OK: all decision trace fixture checks passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6k-disabled.json \
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
    cat /tmp/stage6k-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6K Universal Intent Router decision trace smoke passed"
else
  echo "FAIL: Stage 6K Universal Intent Router decision trace smoke failed"
fi

exit "$fail"
