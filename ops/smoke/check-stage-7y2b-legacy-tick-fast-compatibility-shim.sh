#!/usr/bin/env bash
set -u

echo "=== Stage 7Y-2B smoke: legacy /tick fast compatibility shim source ==="

fail=0
PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7y2b-legacy-tick-fast-compatibility-shim.md"
SRC="edge_controller.py"

for f in "$DOC" "$SRC"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: missing $f"
    fail=1
  fi
done

grep -q "Legacy Tick Fast Compatibility Shim" "$DOC" || fail=1
grep -q "does not re-enable the legacy scheduler timer" "$DOC" || fail=1
grep -q "legacy_tick_compatibility_shim" "$SRC" || fail=1
grep -q "EDGE_LEGACY_TICK_COMPAT_SHIM" "$SRC" || fail=1
grep -q "/workers/remediation/tick" "$SRC" || fail=1
grep -q "/power/auto/tick" "$SRC" || fail=1
grep -q "/power/idle/tick" "$SRC" || fail=1

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile "$SRC" || fail=1

echo
echo "=== verify shim appears before old queued_jobs path ==="
"$PYTHON_BIN" - <<'PY' || fail=1
from pathlib import Path

s = Path("edge_controller.py").read_text()
tick_start = s.index('@app.post("/tick")')
shim_pos = s.index('legacy_tick_compatibility_shim', tick_start)
queued_pos = s.index('queued_jobs = conn.execute', tick_start)

assert shim_pos < queued_pos, "compatibility shim must run before legacy queued_jobs path"
print("OK: /tick shim runs before old legacy queued job path")
PY

echo
echo "=== verify live controller still healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7y2b-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7y2b-health.json || true
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
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7y2b-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7y2b-router.json || true
echo
if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  fail=1
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Y-2B source-only smoke passed"
else
  echo "FAIL: Stage 7Y-2B smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
