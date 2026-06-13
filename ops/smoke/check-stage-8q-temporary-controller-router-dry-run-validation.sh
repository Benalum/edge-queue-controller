#!/usr/bin/env bash
set -u

echo "=== Stage 8Q smoke: temporary controller router dry-run validation ==="

fail=0
PORT=7076
BASE="http://127.0.0.1:${PORT}"
LIVE="http://127.0.0.1:7070"
TEMP_PID=""

DOC="docs/stage-8q-temporary-controller-router-dry-run-validation.md"
REPORT="docs/generated/stage-8q-temporary-controller-router-dry-run-validation.json"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
CONTROLLER="edge_controller.py"

cleanup_temp() {
  if [ -n "$TEMP_PID" ]; then
    if kill -0 "$TEMP_PID" 2>/dev/null; then
      echo "stopping_temp_controller_pid=$TEMP_PID"
      kill "$TEMP_PID" 2>/dev/null || true
      sleep 1
      kill -9 "$TEMP_PID" 2>/dev/null || true
      wait "$TEMP_PID" 2>/dev/null || true
    fi
  fi
}

trap cleanup_temp EXIT

for f in "$DOC" "$APP_JS" "$STUB" "$CONTROLLER"; do
  if [ -f "$f" ]; then
    echo "OK: found $f"
  else
    echo "FAIL: missing $f"
    fail=1
  fi
done

echo
echo "=== doc markers ==="
for marker in \
  "Temporary Controller Router Dry-Run Validation" \
  "127.0.0.1:7076" \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1" \
  "Stage 8R"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== preflight: live controller remains disabled and frontend has no router endpoint ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB"; then
  echo "FAIL: frontend files must not contain /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" || true
  fail=1
else
  echo "OK: frontend files contain no /api/router/dry-run"
fi

if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live controller router env is enabled"
  fail=1
else
  echo "OK: live controller router env is not enabled"
fi

live_code="$(curl -sS --max-time 10 -o /tmp/stage8q-live-router-before.out -w "%{http_code}" \
  -X POST "$LIVE/api/router/dry-run" \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "live_router_before_code=$live_code"
sed -n '1,8p' /tmp/stage8q-live-router-before.out || true

if [ "$live_code" != "404" ]; then
  echo "FAIL: live router should be disabled before temp test"
  fail=1
fi

echo
echo "=== ensure temporary port is free ==="
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: port ${PORT} is already listening"
  ss -ltnp | grep ":${PORT}" || true
  fail=1
else
  echo "OK: port ${PORT} is free"
fi

echo
echo "=== start temporary enabled controller on ${PORT} ==="
PYTHON_BIN=".venv/bin/python"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi

if [ "$fail" = "0" ]; then
  env \
    EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 \
    EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3 \
    "$PYTHON_BIN" -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" \
      >/tmp/stage8q-temp-controller.log 2>&1 &
  TEMP_PID="$!"
  echo "temp_controller_pid=$TEMP_PID"

  ready=0
  for i in $(seq 1 30); do
    code="$(curl -sS --max-time 2 -o /tmp/stage8q-temp-health.out -w "%{http_code}" "$BASE/health" || true)"
    if [ "$code" = "200" ]; then
      ready=1
      echo "OK: temporary controller health is ready"
      break
    fi
    sleep 1
  done

  if [ "$ready" != "1" ]; then
    echo "FAIL: temporary controller did not become ready"
    sed -n '1,120p' /tmp/stage8q-temp-controller.log || true
    fail=1
  fi
fi

echo
echo "=== validate temporary router dry-run decision contracts ==="
if [ "$fail" = "0" ]; then
  python3 - <<'PY' | tee /tmp/stage8q-router-cases.txt
import json
import subprocess
from pathlib import Path

cases = [
    {
        "name": "study_next",
        "payload": {
            "input": {"text": "next", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study"},
        },
        "expected_selected_path": "study_command",
        "expected_legacy": "study.next",
        "expected_intent_key": "study.card.next",
    },
    {
        "name": "study_skip",
        "payload": {
            "input": {"text": "skip", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study"},
        },
        "expected_selected_path": "study_command",
        "expected_legacy": "study.skip",
        "expected_intent_key": "study.card.skip",
    },
    {
        "name": "study_answer",
        "payload": {
            "input": {"text": "show answer", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study"},
        },
        "expected_selected_path": "study_command",
        "expected_legacy": "study.answer",
        "expected_intent_key": "study.card.answer",
    },
    {
        "name": "companion_chat",
        "payload": {
            "input": {"text": "how are you", "source": "companion", "surface": "companion"},
            "context": {"active_page": "companion"},
        },
        "expected_selected_path": "companion_chat",
        "expected_legacy": "companion.chat",
        "expected_intent_key": None,
    },
    {
        "name": "admin_blocked",
        "payload": {
            "input": {"text": "next", "source": "admin", "surface": "admin"},
            "context": {"active_page": "admin"},
        },
        "expected_selected_path": "unsupported",
        "expected_legacy": "unknown.unsupported",
        "expected_intent_key": None,
    },
]

base = "http://127.0.0.1:7076"
results = []
ok = True

for case in cases:
    p = subprocess.run(
        [
            "curl",
            "-sS",
            "--max-time",
            "10",
            "-w",
            "\nHTTP_CODE=%{http_code}\n",
            "-X",
            "POST",
            f"{base}/api/router/dry-run",
            "-H",
            "Content-Type: application/json",
            "--data",
            json.dumps(case["payload"]),
        ],
        capture_output=True,
        text=True,
    )

    out = p.stdout
    body_text, _, code_text = out.partition("\nHTTP_CODE=")
    code = code_text.strip()

    try:
        body = json.loads(body_text)
    except Exception as exc:
        body = {"json_error": str(exc), "raw": body_text}

    decision = body.get("decision_contract") or {}

    result = {
        "name": case["name"],
        "http_code": code,
        "selected_path": decision.get("selected_path"),
        "legacy_intent_name": decision.get("legacy_intent_name"),
        "intent_key": decision.get("intent_key"),
        "dry_run": decision.get("dry_run"),
        "dispatch_performed": decision.get("dispatch_performed"),
        "model_call_required": decision.get("model_call_required"),
        "allowed_to_dispatch": decision.get("allowed_to_dispatch"),
        "eligible_for_dispatch": decision.get("eligible_for_dispatch"),
    }

    checks = [
        code == "200",
        bool(decision),
        decision.get("selected_path") == case["expected_selected_path"],
        decision.get("legacy_intent_name") == case["expected_legacy"],
        decision.get("intent_key") == case["expected_intent_key"],
        decision.get("dry_run") is True,
        decision.get("dispatch_performed") is False,
        decision.get("model_call_required") is False,
        decision.get("allowed_to_dispatch") is False,
        decision.get("eligible_for_dispatch") is False,
    ]

    result["passed"] = all(checks)
    if not result["passed"]:
        ok = False
        result["body"] = body

    results.append(result)
    print(json.dumps(result, sort_keys=True))

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8q-temporary-controller-router-dry-run-validation.json").write_text(
    json.dumps(
        {
            "stage": "8Q",
            "temporary_controller_port": 7076,
            "temporary_router_enabled": True,
            "live_router_enabled": False,
            "frontend_router_traffic_enabled": False,
            "dispatch_enabled": False,
            "model_calls_enabled": False,
            "cases": results,
            "all_cases_passed": ok,
        },
        indent=2,
        sort_keys=True,
    )
    + "\n"
)

if ok:
    print("PASS: Stage 8Q temporary router decision contract cases passed")
else:
    print("FAIL: Stage 8Q temporary router decision contract cases failed")
PY

  if ! grep -q "PASS: Stage 8Q temporary router decision contract cases passed" /tmp/stage8q-router-cases.txt; then
    echo "FAIL: temporary router case validation failed"
    sed -n '1,160p' /tmp/stage8q-temp-controller.log || true
    fail=1
  fi
fi

echo
echo "=== stop temporary controller and verify port closed ==="
cleanup_temp
TEMP_PID=""

closed=0
for i in $(seq 1 10); do
  if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
    sleep 1
  else
    closed=1
    break
  fi
done

if [ "$closed" = "1" ]; then
  echo "OK: temporary controller port ${PORT} is closed"
else
  echo "FAIL: temporary controller port ${PORT} is still listening"
  ss -ltnp | grep ":${PORT}" || true
  fail=1
fi

echo
echo "=== verify live router still disabled after temporary test ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8q-live-after-${path//\//_}.out" -w "%{http_code}" \
    -X POST "$LIVE${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8q-live-after-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: live $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== live router env flag remains off ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live router dry-run env is enabled"
  fail=1
else
  echo "OK: live router dry-run env is not enabled"
fi

echo
echo "=== frontend still has no router endpoint string ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB"; then
  echo "FAIL: frontend files must not contain /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" || true
  fail=1
else
  echo "OK: frontend files contain no /api/router/dry-run"
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 "$LIVE/health" | jq .

curl -sS --max-time 20 "$LIVE/system/status" > /tmp/stage8q-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker")),
  power: (.services[]? | select(.id=="power-automation"))
}' /tmp/stage8q-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8q-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8q-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8q-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8q-system-status.json)"

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
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
power_auto_active="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
remediation_active="$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo "legacy_enabled=$legacy_enabled"
echo "legacy_active=$legacy_active"
echo "power_auto_active=$power_auto_active"
echo "remediation_active=$remediation_active"

if [ "$legacy_enabled" != "disabled" ] || [ "$legacy_active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled/inactive"
  fail=1
fi

if [ "$power_auto_active" != "active" ] || [ "$remediation_active" != "active" ]; then
  echo "FAIL: modern timers should remain active"
  fail=1
fi

echo
echo "=== validate generated Stage 8Q report ==="
if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"stage": "8Q"' "$REPORT" || fail=1
  grep -q '"all_cases_passed": true' "$REPORT" || fail=1
  grep -q '"live_router_enabled": false' "$REPORT" || fail=1
  grep -q '"frontend_router_traffic_enabled": false' "$REPORT" || fail=1
  grep -q '"dispatch_enabled": false' "$REPORT" || fail=1
  grep -q '"model_calls_enabled": false' "$REPORT" || fail=1
  echo "OK: generated Stage 8Q report valid"
else
  echo "FAIL: missing generated Stage 8Q report"
  fail=1
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8Q temporary controller router dry-run validation verified"
else
  echo "FAIL: Stage 8Q smoke found an issue"
fi
