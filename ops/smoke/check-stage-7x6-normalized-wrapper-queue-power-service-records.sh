#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7X-6 smoke: normalized wrapper/queue/power service records source ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7x6-normalized-wrapper-queue-power-service-records.md"
SRC="edge_controller.py"

test -f "$DOC"
test -f "$SRC"

grep -q "Normalized Wrapper Queue Power Service Records" "$DOC"
grep -q "Power Automation is" "$DOC"
grep -q "does not restart the controller" "$DOC"

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile "$SRC"

echo
echo "=== verify source helpers and service IDs exist ==="
"$PYTHON_BIN" - <<'PY'
from pathlib import Path

s = Path("edge_controller.py").read_text()

required = [
    "def _system_systemd_unit_facts(unit_name):",
    "def _system_frontend_wrapper_status(checked_at):",
    "def _system_queue_status_from_worker(checked_at, worker_service):",
    "def _system_power_automation_status(checked_at):",
    '"id": "frontend-wrapper"',
    '"id": "queue"',
    '"id": "power-automation"',
    "services.append(_system_frontend_wrapper_status(checked_at))",
    "services.append(_system_queue_status_from_worker(checked_at, ct101_worker_service))",
    "services.append(_system_power_automation_status(checked_at))",
]

missing = [x for x in required if x not in s]
assert not missing, f"missing expected source markers: {missing}"

print("OK: source includes normalized service records")
PY

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"

if [ "$enabled" != "disabled" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled"
  exit 1
fi

if [ "$active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain inactive"
  exit 1
fi

echo
echo "=== verify live controller still healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7x6-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7x6-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7x6-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7x6-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7X-6 source-only smoke passed"
