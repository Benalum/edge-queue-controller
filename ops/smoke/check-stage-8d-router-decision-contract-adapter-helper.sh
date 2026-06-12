#!/usr/bin/env bash
set -u

echo "=== Stage 8D smoke: router decision contract adapter helper ==="

fail=0
DOC="docs/stage-8d-router-decision-contract-adapter-helper.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Router Decision Contract Adapter Helper" \
  "_stage8d_router_decision_contract" \
  "selected_path" \
  "dispatch_plan" \
  "candidate_routes" \
  "Stage 8E"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== source markers ==="
grep -q "STAGE_8D_DECISION_CONTRACT_ADAPTER_V1" edge_intent_router.py || fail=1
grep -q "def _stage8d_router_decision_contract" edge_intent_router.py || fail=1
grep -q "def _stage8d_selected_path_from_intent" edge_intent_router.py || fail=1

echo
echo "=== compile check ==="
python3 -m py_compile edge_intent_router.py edge_router_schema.py edge_router_seed.py edge_router_lookup.py edge_controller.py
if [ "$?" != "0" ]; then
  echo "FAIL: compile failed"
  fail=1
else
  echo "OK: compile passed"
fi

echo
echo "=== adapter direct unit checks, no HTTP enable, no dispatch ==="
EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3 python3 - <<'PY' | tee /tmp/stage8d-adapter-check.txt
from edge_intent_router import _stage6f_router_response, _stage8d_router_decision_contract

cases = [
    (
        "study next",
        {
            "input": {"text": "next", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "study skip",
        {
            "input": {"text": "skip", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "study answer",
        {
            "input": {"text": "show answer", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "study_command",
    ),
    (
        "companion chat",
        {
            "input": {"text": "how are you", "source": "companion", "surface": "companion_chat"},
            "context": {"active_page": "companion", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "companion_chat",
    ),
    (
        "admin blocked",
        {
            "input": {"text": "next", "source": "admin", "surface": "admin"},
            "context": {"active_page": "admin", "profile_language": "en"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "unsupported",
    ),
]

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

for name, payload, expected_path in cases:
    router_result = _stage6f_router_response(payload)
    decision = _stage8d_router_decision_contract(router_result)

    missing = [key for key in required if key not in decision]
    assert not missing, (name, missing, decision)

    assert decision["dry_run"] is True, (name, decision)
    assert decision["dispatch_performed"] is False, (name, decision)
    assert decision["allowed_to_dispatch"] is False, (name, decision)
    assert decision["selected_path"] == expected_path, (name, decision["selected_path"], decision)
    assert isinstance(decision["candidate_routes"], list), (name, decision)
    assert isinstance(decision["dispatch_plan"], dict), (name, decision)
    assert decision["dispatch_plan"]["dispatch_performed"] is False, (name, decision)
    assert decision["dispatch_plan"]["would_dispatch"] is False, (name, decision)

    print(f"OK: {name}: selected_path={decision['selected_path']} legacy={decision['legacy_intent_name']} intent_key={decision['intent_key']}")

print("PASS: Stage 8D adapter direct checks passed")
PY

grep -q "PASS: Stage 8D adapter direct checks passed" /tmp/stage8d-adapter-check.txt || fail=1

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8d-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"surface":"study","text":"next"}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8d-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8d-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8d-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8d-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8d-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8d-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8d-system-status.json)"

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
  echo "PASS: Stage 8D router decision contract adapter helper verified"
else
  echo "FAIL: Stage 8D smoke found an issue"
fi
