#!/usr/bin/env bash
set -u

echo "=== Stage 8B smoke: Universal Intent Router decision-maker contract ==="

fail=0
DOC="docs/stage-8b-universal-intent-router-decision-maker-contract.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Universal Intent Router Decision-Maker Contract" \
  "selected_path" \
  "study_command" \
  "companion_chat" \
  "model_call_required" \
  "user phrase bank" \
  "dry-run/shadow-only" \
  "Stage 8C"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== verify platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8b-system-status.json
jq '{
  overall_state,
  platform: .normalized.platform,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8b-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8b-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8b-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8b-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8b-system-status.json)"

echo "overall_state=$overall_state"
echo "queue_failed=$queue_failed"
echo "queue_queued=$queue_queued"
echo "queue_running=$queue_running"

if [ "$overall_state" != "online" ]; then
  echo "FAIL: platform should be online"
  fail=1
fi

if [ "$queue_failed" != "0" ] || [ "$queue_queued" != "0" ] || [ "$queue_running" != "0" ]; then
  echo "FAIL: queue should stay clean"
  fail=1
fi

echo
echo "=== verify router live endpoint remains disabled ==="
for path in /api/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8b-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"surface":"study","text":"next"}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8b-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled with 404"
    fail=1
  fi
done

echo
echo "=== compile check remains clean ==="
python3 -m py_compile edge_router_schema.py edge_router_seed.py edge_router_lookup.py edge_controller.py
if [ "$?" != "0" ]; then
  echo "FAIL: compile failed"
  fail=1
else
  echo "OK: compile passed"
fi

echo
echo "=== timer safety unchanged ==="
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8B decision-maker contract documented and verified"
else
  echo "FAIL: Stage 8B smoke found an issue"
fi
