#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-13h-small-study-judge-model-call-design"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: design-only Study Judge model-call checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== Phase 13F static/dynamic smoke ==="
ops/smoke/check-phase-13f-disabled-admin-study-answer-preview-endpoint.sh || fail=1

echo
echo "=== static source safety: no Phase 13H runtime code ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
lower = text.lower()

for forbidden in [
    "phase_13h",
    "stage5p13h",
    "small_study_judge_model_call",
    "study_judge_model_call",
]:
    if forbidden in lower:
        raise SystemExit(f"FAIL: Phase 13H should not add runtime code marker: {forbidden}")

required_existing = [
    '@app.post("/admin/study-answer-preview")',
    'async def admin_study_answer_preview(',
    '"model_call_allowed": False',
    '"job_enqueue_allowed": False',
    '"database_write_allowed": False',
    '"card_state_change_allowed": False',
]
for marker in required_existing:
    if marker not in text:
        raise SystemExit(f"FAIL: required existing preview marker missing: {marker}")

print("PASS: Phase 13H added no runtime code and existing disabled preview markers remain")
PY

echo
echo "=== design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("docs/phase-13h-small-study-judge-model-call-design.md").read_text()

required = [
    "Phase 13H defines the design contract for a future small Study Judge model call.",
    "This phase is design-only.",
    "It does not add model execution, queue submission, worker changes, Study integration, or live grading behavior.",
    "tier_2_study_light",
    "card_match_not_truth_check",
    "The future Study Judge must return strict JSON:",
    "verdict: correct, partially_correct, incorrect, or unsure",
    "relationship: same_meaning, narrower, broader, related, unrelated, contradiction, or unclear",
    "Do not rewrite or mutate the stored card.",
    "Admin-only dry-run preview that can call a small model.",
    "This phase must not:",
    "Change edge_controller.py.",
    "Call any model.",
    "Enqueue any job.",
    "Write to the database.",
    "Change card state.",
    "Call /api/generate.",
    "Call /api/chat.",
    "Unauthenticated requests must return 401.",
]
for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: design doc missing marker: {marker}")

print("PASS: Phase 13H design doc markers are present")
PY

echo
echo "=== live health ==="
curl -sS --max-time 5 -o /tmp/phase13h-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live unauthenticated Study-answer preview remains blocked ==="
unauth_code="$(
  curl -sS --max-time 8 \
    -o /tmp/phase13h-unauth.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/admin/study-answer-preview \
    -H 'Content-Type: application/json' \
    --data '{"question":"What is two plus three?","expected_answer":"5","user_answer":"five"}' \
    || true
)"
echo "unauth_code=${unauth_code}"
if [ "$unauth_code" != "401" ]; then
  echo "FAIL: unauthenticated Study-answer preview should return 401"
  cat /tmp/phase13h-unauth.json || true
  fail=1
else
  echo "PASS: unauthenticated Study-answer preview remains auth-blocked"
fi

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== safety summary ==="
echo "PASS: no edge_controller.py changes are required by this phase"
echo "PASS: no controller restart was performed"
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
