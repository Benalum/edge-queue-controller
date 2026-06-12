#!/usr/bin/env bash
set -u

echo "=== Stage 8E smoke: temporary router decision contract HTTP adapter ==="

fail=0
DOC="docs/stage-8e-temporary-router-decision-contract-http-smoke.md"
PORT="${STAGE8E_PORT:-7073}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG="/tmp/stage8e-router-http-${PORT}.log"
PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"

if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi

temp_pid=""

cleanup() {
  if [ -n "${temp_pid:-}" ] && kill -0 "$temp_pid" >/dev/null 2>&1; then
    echo "cleanup: stopping temporary router pid=$temp_pid"
    kill "$temp_pid" >/dev/null 2>&1 || true
    wait "$temp_pid" >/dev/null 2>&1 || true
  fi
}

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Temporary Router Decision Contract HTTP Smoke" \
  "_stage8d_router_decision_contract" \
  "temporary local controller" \
  "selected_path" \
  "Stage 8F"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== required source markers ==="
grep -q "STAGE_8D_DECISION_CONTRACT_ADAPTER_V1" edge_intent_router.py || fail=1
grep -q "def _stage8d_router_decision_contract" edge_intent_router.py || fail=1

echo
echo "=== compile check ==="
"$PYTHON_BIN" -m py_compile \
  edge_controller.py \
  edge_intent_router.py \
  edge_router_lookup.py \
  edge_router_schema.py \
  edge_router_seed.py

if [ "$?" != "0" ]; then
  echo "FAIL: compile failed"
  fail=1
else
  echo "OK: compile passed"
fi

echo
echo "=== verify live controller remains active and router disabled before temp test ==="
live_active="$(systemctl is-active edge-queue-controller || true)"
echo "live_controller_active=$live_active"
if [ "$live_active" != "active" ]; then
  echo "FAIL: live controller should be active"
  fail=1
fi

for path in /api/router/dry-run /system/router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8e-live-before-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "live_before $path code=$code"
  sed -n '1,8p' "/tmp/stage8e-live-before-${path//\//_}.out" || true
  if [ "$code" != "404" ]; then
    echo "FAIL: live $path should remain disabled"
    fail=1
  fi
done

echo
echo "=== verify temporary port is free ==="
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: temporary port ${PORT} is already in use"
  ss -ltnp | grep ":${PORT}" || true
  fail=1
fi

if [ "$fail" = "0" ]; then
  echo
  echo "=== start temporary enabled controller on ${BASE_URL} ==="
  rm -f "$LOG"

  EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 \
  EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3 \
  "$PYTHON_BIN" -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG" 2>&1 &

  temp_pid="$!"
  echo "temporary_pid=$temp_pid"
  echo "temporary_log=$LOG"

  ready=0
  for i in $(seq 1 50); do
    code="$(curl -sS --max-time 2 -o /tmp/stage8e-temp-health.out -w "%{http_code}" "${BASE_URL}/health" || true)"
    if [ "$code" = "200" ]; then
      ready=1
      break
    fi
    sleep 0.25
  done

  if [ "$ready" != "1" ]; then
    echo "FAIL: temporary controller did not become healthy"
    echo "--- temporary log ---"
    sed -n '1,220p' "$LOG" || true
    fail=1
  else
    echo "OK: temporary controller healthy"
    cat /tmp/stage8e-temp-health.out || true
    echo
  fi
fi

if [ "$fail" = "0" ]; then
  echo
  echo "=== call temporary enabled router cases ==="

  cat > /tmp/stage8e-router-cases.json <<'JSON'
[
  {
    "name": "study_next",
    "payload": {
      "input": {"text": "next", "source": "study", "surface": "study_session"},
      "context": {"active_page": "study", "profile_language": "en"},
      "router_options": {"dry_run": true, "allow_dispatch": false, "allow_model_call": false}
    },
    "expected_selected_path": "study_command"
  },
  {
    "name": "study_skip",
    "payload": {
      "input": {"text": "skip", "source": "study", "surface": "study_session"},
      "context": {"active_page": "study", "profile_language": "en"},
      "router_options": {"dry_run": true, "allow_dispatch": false, "allow_model_call": false}
    },
    "expected_selected_path": "study_command"
  },
  {
    "name": "study_answer",
    "payload": {
      "input": {"text": "show answer", "source": "study", "surface": "study_session"},
      "context": {"active_page": "study", "profile_language": "en"},
      "router_options": {"dry_run": true, "allow_dispatch": false, "allow_model_call": false}
    },
    "expected_selected_path": "study_command"
  },
  {
    "name": "companion_chat",
    "payload": {
      "input": {"text": "how are you", "source": "companion", "surface": "companion_chat"},
      "context": {"active_page": "companion", "profile_language": "en"},
      "router_options": {"dry_run": true, "allow_dispatch": false, "allow_model_call": false}
    },
    "expected_selected_path": "companion_chat"
  },
  {
    "name": "admin_blocked",
    "payload": {
      "input": {"text": "next", "source": "admin", "surface": "admin"},
      "context": {"active_page": "admin", "profile_language": "en"},
      "router_options": {"dry_run": true, "allow_dispatch": false, "allow_model_call": false}
    },
    "expected_selected_path": "unsupported"
  }
]
JSON

  "$PYTHON_BIN" - <<PY | tee /tmp/stage8e-contract-http-check.txt
import json
import subprocess
from pathlib import Path

from edge_intent_router import _stage8d_router_decision_contract

base_url = "${BASE_URL}"
cases = json.loads(Path("/tmp/stage8e-router-cases.json").read_text())

required = [
    "ok",
    "dry_run",
    "dispatch_performed",
    "model_call_required",
    "selected_path",
    "intent_key",
    "legacy_intent_name",
    "confidence",
    "needs_confirmation",
    "reason",
    "surface",
    "context_domain",
    "language_code",
    "decision_trace",
    "candidate_routes",
    "dispatch_plan",
    "allowed_to_dispatch",
    "eligible_for_dispatch",
]

for case in cases:
    name = case["name"]
    payload = case["payload"]
    expected = case["expected_selected_path"]

    proc = subprocess.run(
        [
            "curl",
            "-sS",
            "--max-time",
            "10",
            "-X",
            "POST",
            f"{base_url}/api/router/dry-run",
            "-H",
            "Content-Type: application/json",
            "--data",
            json.dumps(payload),
        ],
        check=True,
        capture_output=True,
        text=True,
    )

    router_result = json.loads(proc.stdout)
    decision = _stage8d_router_decision_contract(router_result)

    out_path = Path(f"/tmp/stage8e-{name}-decision.json")
    out_path.write_text(json.dumps(decision, indent=2, sort_keys=True))

    missing = [key for key in required if key not in decision]
    assert not missing, (name, missing, decision)

    assert decision["ok"] is True, (name, decision)
    assert decision["dry_run"] is True, (name, decision)
    assert decision["dispatch_performed"] is False, (name, decision)
    assert decision["allowed_to_dispatch"] is False, (name, decision)
    assert decision["dispatch_plan"]["dispatch_performed"] is False, (name, decision)
    assert decision["dispatch_plan"]["would_dispatch"] is False, (name, decision)
    assert decision["selected_path"] == expected, (name, expected, decision)

    print(
        f"OK: {name}: selected_path={decision['selected_path']} "
        f"legacy={decision['legacy_intent_name']} "
        f"intent_key={decision['intent_key']}"
    )

print("PASS: Stage 8E temporary HTTP router output adapts to decision contract")
PY

  grep -q "PASS: Stage 8E temporary HTTP router output adapts to decision contract" /tmp/stage8e-contract-http-check.txt || fail=1
fi

echo
echo "=== stop temporary controller ==="
cleanup
temp_pid=""

sleep 0.5
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: temporary port ${PORT} is still listening after cleanup"
  ss -ltnp | grep ":${PORT}" || true
  fail=1
else
  echo "OK: temporary port ${PORT} is closed"
fi

echo
echo "=== verify live controller still active and router still disabled after temp test ==="
live_active_after="$(systemctl is-active edge-queue-controller || true)"
echo "live_controller_active_after=$live_active_after"
if [ "$live_active_after" != "active" ]; then
  echo "FAIL: live controller should still be active"
  fail=1
fi

for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8e-live-after-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "live_after $path code=$code"
  sed -n '1,8p' "/tmp/stage8e-live-after-${path//\//_}.out" || true
  if [ "$code" != "404" ]; then
    echo "FAIL: live $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8e-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8e-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8e-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8e-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8e-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8e-system-status.json)"

echo "overall_state=$overall_state"
echo "queue_failed=$queue_failed"
echo "queue_queued=$queue_queued"
echo "queue_running=$queue_running"

if [ "$overall_state" != "online" ]; then
  echo "FAIL: platform should remain online"
  fail=1
fi

if [ "$queue_failed" != "0" ] || [ "$queue_queued" != "0" ] || [ "$queue_running" != "0" ]; then
  echo "FAIL: queue should remain clean"
  fail=1
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
  echo "PASS: Stage 8E temporary router decision contract HTTP smoke verified"
else
  echo "FAIL: Stage 8E smoke found an issue"
fi
