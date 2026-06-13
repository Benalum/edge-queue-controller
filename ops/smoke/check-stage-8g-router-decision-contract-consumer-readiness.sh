#!/usr/bin/env bash
set -u

echo "=== Stage 8G smoke: router decision_contract consumer readiness ==="

fail=0
DOC="docs/stage-8g-router-decision-contract-consumer-readiness.md"
FIXTURE="docs/generated/stage-8g-router-decision-contract-consumer-fixtures.json"
PORT="${STAGE8G_PORT:-7075}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG="/tmp/stage8g-router-http-${PORT}.log"
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
  "Router Decision Contract Consumer Readiness" \
  "decision_contract.selected_path" \
  "dispatch_plan.would_dispatch" \
  "Generated Fixture" \
  "Stage 8H"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== source markers ==="
grep -q "STAGE_8F_ROUTER_RESPONSE_DECISION_CONTRACT_V1" edge_intent_router.py || fail=1
grep -q 'result\["decision_contract"\] = decision_contract' edge_intent_router.py || fail=1

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
echo "=== verify live controller active and router disabled before temporary test ==="
live_active="$(systemctl is-active edge-queue-controller || true)"
echo "live_controller_active=$live_active"
if [ "$live_active" != "active" ]; then
  echo "FAIL: live controller should be active"
  fail=1
fi

for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8g-live-before-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "live_before $path code=$code"
  sed -n '1,8p' "/tmp/stage8g-live-before-${path//\//_}.out" || true
  if [ "$code" != "404" ]; then
    echo "FAIL: live $path should remain disabled/not found"
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
  for i in $(seq 1 60); do
    code="$(curl -sS --max-time 2 -o /tmp/stage8g-temp-health.out -w "%{http_code}" "${BASE_URL}/health" || true)"
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
    cat /tmp/stage8g-temp-health.out || true
    echo
  fi
fi

if [ "$fail" = "0" ]; then
  echo
  echo "=== temporary HTTP consumer-readiness cases ==="

  "$PYTHON_BIN" - <<PY | tee /tmp/stage8g-consumer-readiness-check.txt
import json
import subprocess
from pathlib import Path

base_url = "${BASE_URL}"
fixture_path = Path("${FIXTURE}")

cases = [
    (
        "study_next",
        {
            "input": {"text": "next", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "study_skip",
        {
            "input": {"text": "skip", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "study_answer",
        {
            "input": {"text": "show answer", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "companion_chat",
        {
            "input": {"text": "how are you", "source": "companion", "surface": "companion_chat"},
            "context": {"active_page": "companion", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "companion_chat",
    ),
    (
        "admin_blocked",
        {
            "input": {"text": "next", "source": "admin", "surface": "admin"},
            "context": {"active_page": "admin", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "unsupported",
    ),
]

def consumer_view(data):
    decision = data.get("decision_contract") or {}
    plan = decision.get("dispatch_plan") or {}
    return {
        "selected_path": decision.get("selected_path"),
        "intent_key": decision.get("intent_key"),
        "legacy_intent_name": decision.get("legacy_intent_name"),
        "confidence": decision.get("confidence"),
        "needs_confirmation": decision.get("needs_confirmation"),
        "dispatch_performed": decision.get("dispatch_performed"),
        "allowed_to_dispatch": decision.get("allowed_to_dispatch"),
        "eligible_for_dispatch": decision.get("eligible_for_dispatch"),
        "model_call_required": decision.get("model_call_required"),
        "would_dispatch": plan.get("would_dispatch"),
    }

fixtures = []

for name, payload, expected_path in cases:
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

    data = json.loads(proc.stdout)
    view = consumer_view(data)

    assert view["selected_path"] == expected_path, (name, expected_path, view)
    assert view["dispatch_performed"] is False, (name, view)
    assert view["allowed_to_dispatch"] is False, (name, view)
    assert view["would_dispatch"] is False, (name, view)
    assert "router_result" not in data["decision_contract"], (name, data["decision_contract"])

    fixtures.append(
        {
            "name": name,
            "expected_selected_path": expected_path,
            "consumer_view": view,
        }
    )

    print(
        f"OK: {name}: selected_path={view['selected_path']} "
        f"legacy={view['legacy_intent_name']} "
        f"intent_key={view['intent_key']} "
        f"would_dispatch={view['would_dispatch']}"
    )

fixture_path.parent.mkdir(parents=True, exist_ok=True)
fixture_path.write_text(json.dumps({"stage": "8G", "fixtures": fixtures}, indent=2, sort_keys=True) + "\\n")

print(f"wrote_fixture={fixture_path}")
print("PASS: Stage 8G consumer-readiness checks passed")
PY

  grep -q "PASS: Stage 8G consumer-readiness checks passed" /tmp/stage8g-consumer-readiness-check.txt || fail=1
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
echo "=== validate generated fixture ==="
if [ -f "$FIXTURE" ]; then
  python3 -m json.tool "$FIXTURE" >/dev/null
  grep -q '"stage": "8G"' "$FIXTURE" || fail=1
  grep -q '"selected_path": "study_command"' "$FIXTURE" || fail=1
  grep -q '"selected_path": "companion_chat"' "$FIXTURE" || fail=1
  grep -q '"selected_path": "unsupported"' "$FIXTURE" || fail=1
  echo "OK: generated fixture valid"
else
  echo "FAIL: missing generated fixture $FIXTURE"
  fail=1
fi

echo
echo "=== verify live controller still active and router disabled after temporary test ==="
live_active_after="$(systemctl is-active edge-queue-controller || true)"
echo "live_controller_active_after=$live_active_after"
if [ "$live_active_after" != "active" ]; then
  echo "FAIL: live controller should still be active"
  fail=1
fi

for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8g-live-after-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "live_after $path code=$code"
  sed -n '1,8p' "/tmp/stage8g-live-after-${path//\//_}.out" || true
  if [ "$code" != "404" ]; then
    echo "FAIL: live $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8g-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8g-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8g-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8g-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8g-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8g-system-status.json)"

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
  echo "PASS: Stage 8G router decision_contract consumer readiness verified"
else
  echo "FAIL: Stage 8G smoke found an issue"
fi
