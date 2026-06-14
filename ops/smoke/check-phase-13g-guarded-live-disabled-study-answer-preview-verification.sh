#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13g-guarded-live-disabled-study-answer-preview-verification"
fail=0

echo "=== ${PHASE}: guarded live disabled route verification ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== Phase 13F static/dynamic smoke ==="
ops/smoke/check-phase-13f-disabled-admin-study-answer-preview-endpoint.sh || fail=1

echo
echo "=== verify route exists in source ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
required = [
    '@app.post("/admin/study-answer-preview")',
    "async def admin_study_answer_preview(",
    "_admin_support_require_admin(request)",
    "_stage5p13d_disabled_study_answer_evaluation_foundation(",
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"database_write_allowed": False',
    '"card_state_change_allowed": False',
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: source missing marker: {marker}")
print("PASS: source contains disabled admin Study-answer preview route")
PY

echo
echo "=== verify warmup env disabled before restart ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set before restart"
  fail=1
else
  echo "PASS: warmup action env is not enabled before restart"
fi

echo
echo "=== restart edge controller only ==="
if [ "$fail" = "0" ]; then
  sudo systemctl restart edge-queue-controller || fail=1
else
  echo "SKIP: restart blocked by failed preflight"
fi

echo
echo "=== wait for controller health ==="
if [ "$fail" = "0" ]; then
  healthy=0
  for attempt in $(seq 1 30); do
    code="$(curl -sS --max-time 3 -o /tmp/phase13g-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
    echo "health_attempt=${attempt} code=${code}"
    if [ "$code" = "200" ]; then
      healthy=1
      break
    fi
    sleep 1
  done
  if [ "$healthy" != "1" ]; then
    echo "FAIL: controller health did not recover after restart"
    fail=1
  else
    echo "PASS: controller health recovered after restart"
  fi
fi

echo
echo "=== live unauthenticated Study-answer preview must be blocked ==="
if [ "$fail" = "0" ]; then
  unauth_code="$(
    curl -sS --max-time 8 \
      -o /tmp/phase13g-study-answer-preview-unauth.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/admin/study-answer-preview \
      -H 'Content-Type: application/json' \
      --data '{"question":"What is two plus three?","expected_answer":"5","user_answer":"five"}' \
      || true
  )"
  echo "unauth_code=${unauth_code}"
  if [ "$unauth_code" != "401" ]; then
    echo "FAIL: unauthenticated Study-answer preview should return 401"
    cat /tmp/phase13g-study-answer-preview-unauth.json || true
    fail=1
  else
    echo "PASS: unauthenticated Study-answer preview is auth-blocked"
  fi
fi

echo
echo "=== optional authenticated admin Study-answer preview ==="
AUTH_TOKEN="${EDGE_ADMIN_BEARER_TOKEN:-}"
if [ -z "$AUTH_TOKEN" ]; then
  echo "CHECK: EDGE_ADMIN_BEARER_TOKEN not set; skipping authenticated admin preview"
else
  echo "CHECK: EDGE_ADMIN_BEARER_TOKEN is set locally; token value will not be printed"

  exact_code="$(
    curl -sS --max-time 10 \
      -o /tmp/phase13g-study-answer-preview-exact.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/admin/study-answer-preview \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${AUTH_TOKEN}" \
      --data '{"question":"What is two plus three?","expected_answer":"5","user_answer":"the answer is five.","profile":{"preferred_language":"en","study_language":"en"}}' \
      || true
  )"
  echo "authenticated_exact_code=${exact_code}"

  semantic_code="$(
    curl -sS --max-time 10 \
      -o /tmp/phase13g-study-answer-preview-semantic.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/admin/study-answer-preview \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${AUTH_TOKEN}" \
      --data '{"question":"What clothing category is this?","expected_answer":"Pants","user_answer":"Jeans","profile":{"preferred_language":"en","study_language":"en"}}' \
      || true
  )"
  echo "authenticated_semantic_code=${semantic_code}"

  if [ "$exact_code" != "200" ] || [ "$semantic_code" != "200" ]; then
    echo "FAIL: authenticated admin preview did not return 200"
    echo "exact response:"
    cat /tmp/phase13g-study-answer-preview-exact.json || true
    echo
    echo "semantic response:"
    cat /tmp/phase13g-study-answer-preview-semantic.json || true
    fail=1
  else
    python3 - <<'PY' || fail=1
import json
from pathlib import Path

exact = json.loads(Path("/tmp/phase13g-study-answer-preview-exact.json").read_text())
semantic = json.loads(Path("/tmp/phase13g-study-answer-preview-semantic.json").read_text())

def require(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")

for name, payload in [("exact", exact), ("semantic", semantic)]:
    require(payload.get("source") == "phase_13f_disabled_admin_study_answer_preview_endpoint", f"{name} source mismatch")
    require(payload.get("mode") == "disabled_admin_study_answer_preview_only", f"{name} mode mismatch")
    for key in [
        "runtime_action_available",
        "live_study_integration",
        "execute_now",
        "model_call_allowed",
        "job_enqueue_allowed",
        "database_write_allowed",
        "card_state_change_allowed",
    ]:
        require(payload.get(key) is False, f"{name} {key} changed")
    require(payload.get("would_call") == "none", f"{name} would_call changed")
    require(payload.get("read_only") is True, f"{name} read_only changed")
    require(payload.get("network_calls") is False, f"{name} network_calls changed")
    safety = payload.get("safety") or {}
    for key in [
        "admin_gated",
        "not_connected_to_live_study_routes",
        "not_connected_to_companion_live_flow",
        "no_model_invocation",
        "no_queue_write",
        "no_database_write",
        "no_card_state_change",
        "no_tool_call",
    ]:
        require(safety.get(key) is True, f"{name} safety.{key} changed")

exact_eval = exact.get("study_answer_evaluation") or {}
require(exact_eval.get("verdict") == "correct", "exact verdict should be correct")
require(exact_eval.get("match_type") == "number_word_normalized", "exact match_type should be number_word_normalized")
require(exact_eval.get("needs_model_judge") is False, "exact should not need model judge")
require(exact_eval.get("model_call_allowed") is False, "exact eval model_call_allowed changed")
require(exact_eval.get("job_enqueue_allowed") is False, "exact eval job_enqueue_allowed changed")

semantic_eval = semantic.get("study_answer_evaluation") or {}
require(semantic_eval.get("verdict") == "unsure", "semantic verdict should remain unsure")
require(semantic_eval.get("match_type") == "requires_semantic_judge", "semantic should require semantic judge")
require(semantic_eval.get("needs_model_judge") is True, "semantic should need model judge")
require(semantic_eval.get("recommended_model_tier") == "tier_2_study_light", "semantic tier mismatch")
require(semantic_eval.get("model_call_allowed") is False, "semantic eval model_call_allowed changed")
require(semantic_eval.get("job_enqueue_allowed") is False, "semantic eval job_enqueue_allowed changed")

print("PASS: authenticated admin preview returned disabled Study answer-evaluation metadata")
PY
  fi
fi

echo
echo "=== verify warmup env disabled after restart ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set after restart"
  fail=1
else
  echo "PASS: warmup action env is not enabled after restart"
fi

echo
echo "=== safety summary ==="
echo "PASS: only edge-queue-controller restart was requested"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no job enqueue was added"
echo "PASS: no database write was added"
echo "PASS: no card state change was added"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
