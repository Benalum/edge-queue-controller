#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7W-3 smoke: legacy /tick pause parser helper fixed ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7w3-fix-legacy-tick-pause-parser-helper.md"

test -f "$DOC"
test -f edge_controller.py

grep -q "Stage 7W-3 Fix Legacy Tick Pause Parser Helper" "$DOC"
grep -q "_parse_int_env" "$DOC"
grep -q "does not restart the controller" "$DOC"

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile edge_controller.py

echo
echo "=== verify /tick no longer uses missing _parse_int_env helper ==="
"$PYTHON_BIN" - <<'PY'
from pathlib import Path

s = Path("edge_controller.py").read_text()

assert "pause_after_start_minutes=web_presence_start_pause_minutes" in s
assert 'os.getenv("WEB_POWER_START_PAUSE_MINUTES", "10")' in s
assert "web_presence_start_pause_minutes = max(1, min(120, web_presence_start_pause_minutes))" in s

old_bad_block = """web_presence_start_pause_minutes = _parse_int_env(
            "WEB_POWER_START_PAUSE_MINUTES",
            10,
            minimum=1,
            maximum=120,
        )"""

assert old_bad_block not in s, "legacy /tick must not use missing _parse_int_env helper for pause minutes"

local_parse_block = """try:
            web_presence_start_pause_minutes = int(os.getenv("WEB_POWER_START_PAUSE_MINUTES", "10"))
        except (TypeError, ValueError):
            web_presence_start_pause_minutes = 10
        web_presence_start_pause_minutes = max(1, min(120, web_presence_start_pause_minutes))"""

assert local_parse_block in s, "legacy /tick local bounded int parser missing"

print("OK: legacy /tick pause minutes use local bounded int parsing")
PY

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"

if [ "$enabled" != "disabled" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled until controlled restart"
  exit 1
fi

if [ "$active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain inactive until controlled restart"
  exit 1
fi

echo
echo "=== verify controller still healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7w3-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7w3-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should remain 200"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7w3-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7w3-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7W-3 source-only smoke passed"
