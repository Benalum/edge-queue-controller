#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7W-1 smoke: source-only legacy /tick NameError fix ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7w1-fix-legacy-tick-web-presence-pause-nameerror.md"

test -f "$DOC"
test -f edge_controller.py

grep -q "Stage 7W-1 Fix Legacy Tick Web Presence Pause NameError" "$DOC"
grep -q "WEB_POWER_START_PAUSE_MINUTES" "$DOC"
grep -q "source-only" "$DOC"
grep -q "does not enable router dispatch" "$DOC"

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile edge_controller.py

echo
echo "=== verify bounded pause assignment exists before call ==="
"$PYTHON_BIN" - <<'PY'
from pathlib import Path

s = Path("edge_controller.py").read_text()

assign = '''web_presence_start_pause_minutes = _parse_int_env(
            "WEB_POWER_START_PAUSE_MINUTES",
            10,
            minimum=1,
            maximum=120,
        )'''

call = "pause_after_start_minutes=web_presence_start_pause_minutes"

assert assign in s, "bounded web_presence_start_pause_minutes assignment missing"
assert call in s, "pause_after_start_minutes call missing"
assert s.index(assign) < s.index(call), "assignment must appear before call"

print("OK: /tick defines web_presence_start_pause_minutes before use")
PY

echo
echo "=== verify controller remains healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7w1-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7w1-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: live controller health should be 200"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7w1-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7w1-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7W-1 source-only smoke passed"
