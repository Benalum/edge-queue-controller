#!/usr/bin/env bash
set -u

echo "=== Stage 7Z-6 smoke: stale llms-worker-1 registry row removed ==="

fail=0
DOC="docs/stage-7z6-remove-stale-llms-worker-registry-row.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

grep -q "Remove Stale llms-worker-1 Registry Row" "$DOC" || fail=1
if grep -q "llms-worker-1" "$DOC"; then
  echo "OK: doc mentions llms-worker-1"
else
  echo "FAIL: doc should mention llms-worker-1"
  fail=1
fi

if grep -q "worker_events" "$DOC" && grep -q "history was kept" "$DOC"; then
  echo "OK: doc says worker_events history was kept"
else
  echo "FAIL: doc should say worker_events history was kept"
  fail=1
fi

echo
echo "=== verify backup exists ==="
backup="$(ls -1t edge_queue.sqlite3.bak-stage7z6-remove-stale-worker-* 2>/dev/null | head -n 1 || true)"
echo "latest_backup=$backup"
if [ -z "$backup" ] || [ ! -f "$backup" ]; then
  echo "FAIL: Stage 7Z-6 SQLite backup not found"
  fail=1
fi

echo
echo "=== verify stale row absent and worker_events history kept ==="
python3 - <<'PY' | tee /tmp/stage7z6-db-check.txt
import sqlite3

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row

worker_count = conn.execute(
    "SELECT COUNT(*) AS n FROM workers WHERE worker_id = 'llms-worker-1'"
).fetchone()["n"]

event_count = conn.execute(
    "SELECT COUNT(*) AS n FROM worker_events WHERE worker_id = 'llms-worker-1'"
).fetchone()["n"]

total_workers = conn.execute("SELECT COUNT(*) AS n FROM workers").fetchone()["n"]

print(f"stale_worker_count={worker_count}")
print(f"worker_events_history_count={event_count}")
print(f"total_workers={total_workers}")

conn.close()
PY

grep -q "stale_worker_count=0" /tmp/stage7z6-db-check.txt || fail=1
grep -q "worker_events_history_count=3" /tmp/stage7z6-db-check.txt || fail=1

echo
echo "=== verify old heartbeat remains disabled and managed worker active ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
echo old_timer_enabled=\$(systemctl is-enabled ai-platform-edge-heartbeat.timer || true)
echo old_timer_active=\$(systemctl is-active ai-platform-edge-heartbeat.timer || true)
echo managed_worker_enabled=\$(systemctl is-enabled ai-platform-laptop-queue-worker.service || true)
echo managed_worker_active=\$(systemctl is-active ai-platform-laptop-queue-worker.service || true)
"' | tee /tmp/stage7z6-ct101-units.txt

grep -q "old_timer_enabled=disabled" /tmp/stage7z6-ct101-units.txt || fail=1
grep -q "old_timer_active=inactive" /tmp/stage7z6-ct101-units.txt || fail=1
grep -q "managed_worker_enabled=enabled" /tmp/stage7z6-ct101-units.txt || fail=1
grep -q "managed_worker_active=active" /tmp/stage7z6-ct101-units.txt || fail=1

echo
echo "=== verify /workers/registry remains clean ==="
curl -sS --max-time 20 http://127.0.0.1:7070/workers/registry \
  | tee /tmp/stage7z6-workers-registry.json \
  | jq '.'

registry_total="$(jq -r '.summary.total // empty' /tmp/stage7z6-workers-registry.json)"
registry_unhealthy="$(jq -r '.summary.unhealthy // empty' /tmp/stage7z6-workers-registry.json)"
echo "registry_total=$registry_total"
echo "registry_unhealthy=$registry_unhealthy"

if [ "$registry_total" != "0" ] || [ "$registry_unhealthy" != "0" ]; then
  echo "FAIL: registry should have no stale workers"
  fail=1
fi

echo
echo "=== verify remediation sees no stale worker ==="
curl -sS --max-time 20 -X POST http://127.0.0.1:7070/workers/remediation/tick \
  | tee /tmp/stage7z6-remediation.json \
  | jq '.'

worker_count="$(jq -r '.worker_count // empty' /tmp/stage7z6-remediation.json)"
echo "remediation_worker_count=$worker_count"

if [ "$worker_count" != "0" ]; then
  echo "FAIL: remediation should see zero legacy workers"
  fail=1
fi

echo
echo "=== verify platform remains online ==="
curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage7z6-system-status.json
jq '.normalized.platform' /tmp/stage7z6-system-status.json

for id in backend-api frontend-wrapper queue workers ct101-laptop-queue-worker power-automation; do
  state="$(jq -r --arg id "$id" '.normalized.platform[] | select(.id==$id) | .state' /tmp/stage7z6-system-status.json)"
  echo "$id=$state"
  if [ "$state" != "online" ]; then
    echo "FAIL: $id should be online"
    fail=1
  fi
done

echo
echo "=== verify final health and timer safety ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Z-6 stale llms-worker registry cleanup documented and verified"
else
  echo "FAIL: Stage 7Z-6 smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
