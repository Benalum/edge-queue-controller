#!/usr/bin/env bash
set -u

echo "=== Stage 8C smoke: router response schema comparison audit ==="

fail=0
DOC="docs/stage-8c-router-response-schema-comparison-audit.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Router Response Schema Comparison Audit" \
  "selected_path" \
  "legacy_intent_name" \
  "needs_confirmation" \
  "candidate_routes" \
  "dispatch_plan" \
  "Stage 8D"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== platform health remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8c-system-status.json
jq '{
  overall_state,
  platform: .normalized.platform,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8c-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8c-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8c-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8c-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8c-system-status.json)"

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
echo "=== live router endpoint should remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8c-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"surface":"study","text":"next"}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8c-${path//\//_}.out" || true

  if [ "$path" = "/router/dry-run" ]; then
    if [ "$code" != "404" ]; then
      echo "FAIL: $path should remain not found"
      fail=1
    fi
  else
    if [ "$code" != "404" ]; then
      echo "FAIL: $path should remain disabled"
      fail=1
    fi
  fi
done

echo
echo "=== static schema gap check ==="
python3 - <<'PY' | tee /tmp/stage8c-static-gap-check.txt
from pathlib import Path

contract = Path("docs/stage-8b-universal-intent-router-decision-maker-contract.md").read_text()
code = "\n".join([
    Path("edge_controller.py").read_text(),
    Path("edge_intent_router.py").read_text(),
    Path("edge_router_lookup.py").read_text(),
])

terms = [
    "selected_path",
    "legacy_intent_name",
    "needs_confirmation",
    "candidate_routes",
    "dispatch_plan",
]

for term in terms:
    print(f"{term}: contract={term in contract} code={term in code}")
PY

for term in selected_path legacy_intent_name needs_confirmation candidate_routes dispatch_plan; do
  if grep -q "$term: contract=True code=False" /tmp/stage8c-static-gap-check.txt; then
    echo "OK: expected schema gap confirmed for $term"
  else
    echo "FAIL: expected schema gap not confirmed for $term"
    fail=1
  fi
done

echo
echo "=== router DB table sanity ==="
python3 - <<'PY' | tee /tmp/stage8c-router-db-sanity.txt
import sqlite3

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row

for table in ["intent_definitions", "intent_routes", "global_phrase_bank", "user_phrase_bank", "router_logs", "router_resolution_steps"]:
    exists = conn.execute(
        "SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()["n"]
    print(f"{table}_exists={bool(exists)}")
    if exists:
        n = conn.execute(f"SELECT COUNT(*) AS n FROM {table}").fetchone()["n"]
        print(f"{table}_count={n}")

conn.close()
PY

for marker in \
  "intent_definitions_exists=True" \
  "intent_routes_exists=True" \
  "global_phrase_bank_exists=True" \
  "user_phrase_bank_exists=True" \
  "router_logs_exists=True" \
  "router_resolution_steps_exists=True"; do
  grep -q "$marker" /tmp/stage8c-router-db-sanity.txt || fail=1
done

echo
echo "=== compile remains clean ==="
python3 -m py_compile edge_intent_router.py edge_router_schema.py edge_router_seed.py edge_router_lookup.py edge_controller.py
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
  echo "PASS: Stage 8C router schema comparison audit documented and verified"
else
  echo "FAIL: Stage 8C smoke found an issue"
fi
