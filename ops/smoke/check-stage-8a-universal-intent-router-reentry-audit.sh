#!/usr/bin/env bash
set -u

echo "=== Stage 8A smoke: Universal Intent Router re-entry audit ==="

fail=0
DOC="docs/stage-8a-universal-intent-router-reentry-audit.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Universal Intent Router Re-entry Audit" \
  "POST /api/router/dry-run" \
  "edge_router_schema.py" \
  "global_phrase_bank" \
  "study.card.next" \
  "Stage 8B"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== platform health ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8a-system-status.json
jq '{
  overall_state,
  platform: .normalized.platform,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8a-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8a-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8a-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8a-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8a-system-status.json)"

echo "overall_state=$overall_state"
echo "queue_failed=$queue_failed"
echo "queue_queued=$queue_queued"
echo "queue_running=$queue_running"

if [ "$overall_state" != "online" ]; then
  echo "FAIL: platform should be online"
  fail=1
fi

if [ "$queue_failed" != "0" ] || [ "$queue_queued" != "0" ] || [ "$queue_running" != "0" ]; then
  echo "FAIL: queue should be clean"
  fail=1
fi

echo
echo "=== router live endpoint should remain disabled ==="
for path in /api/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8a-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"surface":"study","text":"next"}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8a-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled with 404"
    fail=1
  fi
done

echo
echo "=== router modules compile ==="
python3 -m py_compile edge_router_schema.py edge_router_seed.py edge_router_lookup.py edge_controller.py
if [ "$?" != "0" ]; then
  echo "FAIL: router/controller compile failed"
  fail=1
else
  echo "OK: router/controller compile passed"
fi

echo
echo "=== router DB seed sanity ==="
python3 - <<'PY' | tee /tmp/stage8a-router-db.txt
import sqlite3

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row

tables = {
    row["name"]
    for row in conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    )
}

for table in ["global_phrase_bank", "intent_definitions", "intent_routes", "router_logs"]:
    print(f"{table}_exists={table in tables}")

if "global_phrase_bank" in tables:
    for intent in ["study.card.next", "study.card.skip", "study.card.answer"]:
        n = conn.execute(
            "SELECT COUNT(*) AS n FROM global_phrase_bank WHERE intent_key = ? AND enabled = 1",
            (intent,),
        ).fetchone()["n"]
        print(f"{intent}_phrase_count={n}")

conn.close()
PY

for marker in \
  "global_phrase_bank_exists=True" \
  "intent_definitions_exists=True" \
  "intent_routes_exists=True" \
  "router_logs_exists=True"; do
  grep -q "$marker" /tmp/stage8a-router-db.txt || fail=1
done

for intent in "study.card.next" "study.card.skip" "study.card.answer"; do
  count="$(grep "^${intent}_phrase_count=" /tmp/stage8a-router-db.txt | cut -d= -f2 || true)"
  echo "$intent count=$count"
  if [ -z "$count" ] || [ "$count" = "0" ]; then
    echo "FAIL: expected enabled phrases for $intent"
    fail=1
  fi
done

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
  echo "PASS: Stage 8A router re-entry audit documented and verified"
else
  echo "FAIL: Stage 8A smoke found an issue"
fi
