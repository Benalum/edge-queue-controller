#!/usr/bin/env bash
set -u

echo "=== Stage 7Z-4 smoke: old CT101 edge heartbeat disabled, managed worker active ==="

fail=0
DOC="docs/stage-7z4-disable-old-ct101-edge-heartbeat.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

grep -q "Disable Old CT101 Edge Heartbeat" "$DOC" || fail=1
grep -q "ai-platform-edge-heartbeat.timer" "$DOC" || fail=1
grep -q "ai-platform-laptop-queue-worker.service" "$DOC" || fail=1

echo
echo "=== verify CT101 systemd state ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
echo old_timer_enabled=\$(systemctl is-enabled ai-platform-edge-heartbeat.timer || true)
echo old_timer_active=\$(systemctl is-active ai-platform-edge-heartbeat.timer || true)
echo old_service_enabled=\$(systemctl is-enabled ai-platform-edge-heartbeat.service || true)
echo old_service_active=\$(systemctl is-active ai-platform-edge-heartbeat.service || true)
echo managed_worker_enabled=\$(systemctl is-enabled ai-platform-laptop-queue-worker.service || true)
echo managed_worker_active=\$(systemctl is-active ai-platform-laptop-queue-worker.service || true)
echo managed_queue_controller_active=\$(systemctl is-active ai-platform-queue-controller.service || true)
"' | tee /tmp/stage7z4-ct101-units.txt

grep -q "old_timer_enabled=disabled" /tmp/stage7z4-ct101-units.txt || fail=1
grep -q "old_timer_active=inactive" /tmp/stage7z4-ct101-units.txt || fail=1
grep -q "managed_worker_enabled=enabled" /tmp/stage7z4-ct101-units.txt || fail=1
grep -q "managed_worker_active=active" /tmp/stage7z4-ct101-units.txt || fail=1

echo
echo "=== verify old heartbeat stayed quiet and managed heartbeat continues ==="
sleep 20

old_lines="$(journalctl -u edge-queue-controller --since "25 seconds ago" --no-pager \
  | grep -E 'POST /workers/heartbeat HTTP' \
  | tail -n 40 || true)"
printf '%s\n' "$old_lines"

if [ -n "$old_lines" ]; then
  echo "FAIL: old /workers/heartbeat still appeared"
  fail=1
else
  echo "OK: old /workers/heartbeat stayed quiet"
fi

managed_lines="$(journalctl -u edge-queue-controller --since "25 seconds ago" --no-pager \
  | grep -E 'POST /internal/laptop-queue/workers/(register|heartbeat)|POST /internal/laptop-queue/jobs/claim' \
  | tail -n 80 || true)"
printf '%s\n' "$managed_lines"

if [ -z "$managed_lines" ]; then
  echo "FAIL: managed laptop queue worker activity not observed"
  fail=1
else
  echo "OK: managed laptop queue worker activity observed"
fi

echo
echo "=== verify platform status remains online ==="
curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage7z4-system-status.json
jq '.normalized.platform' /tmp/stage7z4-system-status.json

for id in backend-api frontend-wrapper queue workers ct101-laptop-queue-worker power-automation; do
  state="$(jq -r --arg id "$id" '.normalized.platform[] | select(.id==$id) | .state' /tmp/stage7z4-system-status.json)"
  echo "$id=$state"
  if [ "$state" != "online" ]; then
    echo "FAIL: $id should be online"
    fail=1
  fi
done

echo
echo "=== verify controller health and timer safety ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Z-4 old CT101 heartbeat disabled and managed worker active"
else
  echo "FAIL: Stage 7Z-4 smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
