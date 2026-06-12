#!/usr/bin/env bash
set -u

echo "=== Stage 7Y-3 smoke: Power Automation online when legacy tick is retired ==="

fail=0
PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7y3-power-automation-online-with-retired-legacy-tick.md"
SRC="edge_controller.py"

check_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "FAIL: missing $f"
    fail=1
  else
    echo "OK: found $f"
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE "$pattern" "$file"; then
    echo "OK: $label"
  else
    echo "FAIL: missing marker for $label"
    echo "pattern=$pattern"
    echo "file=$file"
    fail=1
  fi
}

check_file "$DOC"
check_file "$SRC"

check_grep 'Power Automation Online With Retired Legacy Tick' "$DOC" "doc title"
check_grep 'legacy.*tick.*retired|legacy `/tick` is retired|legacy /tick is retired' "$DOC" "doc legacy tick retired explanation"
check_grep 'legacy_tick_retired = _parse_bool_env' "$SRC" "source legacy_tick_retired flag"
check_grep 'legacy /tick scheduler is retired and intentionally disabled' "$SRC" "source online retired legacy detail"

echo
echo "=== compile controller ==="
if "$PYTHON_BIN" -m py_compile "$SRC"; then
  echo "OK: controller compiles"
else
  echo "FAIL: controller compile failed"
  fail=1
fi

echo
echo "=== verify live controller still healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7y3-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7y3-health.json | jq . || cat /tmp/stage7y3-health.json || true
echo
if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  fail=1
fi

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"
if [ "$enabled" != "disabled" ] || [ "$active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled/inactive"
  fail=1
fi

echo
echo "=== verify modern timers are active ==="
power_auto_active="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
remediation_active="$(systemctl is-active edge-queue-remediation-tick.timer || true)"
echo "power_auto_timer_active=$power_auto_active"
echo "remediation_timer_active=$remediation_active"
if [ "$power_auto_active" != "active" ] || [ "$remediation_active" != "active" ]; then
  echo "FAIL: modern timers should be active"
  fail=1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7y3-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7y3-router.json || true
echo
if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  fail=1
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Y-3 source-only smoke passed"
else
  echo "FAIL: Stage 7Y-3 smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
