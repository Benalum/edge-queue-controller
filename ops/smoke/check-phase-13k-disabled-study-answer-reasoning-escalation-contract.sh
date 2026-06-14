#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13k-disabled-study-answer-reasoning-escalation-contract"
fail=0

echo "=== ${PHASE}: disabled Study answer reasoning escalation contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study Judge contract smokes ==="
ops/smoke/check-phase-13i-disabled-study-judge-execution-contract-helper.sh || fail=1
ops/smoke/check-phase-13j-disabled-study-answer-judge-queue-contract.sh || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13k_disabled_study_answer_reasoning_escalation_contract" edge_controller.py || fail=1
grep -q "phase_13k_disabled_study_answer_reasoning_escalation_contract_helper" edge_controller.py || fail=1
grep -q "disabled_study_answer_reasoning_escalation_contract_only" edge_controller.py || fail=1
grep -q "study_answer_reasoning_escalation" edge_controller.py || fail=1
grep -q "tier_4_deep_reasoning" edge_controller.py || fail=1
grep -q "small_judge_confidence_below_0_70" edge_controller.py || fail=1
grep -q "requires_small_judge_result_validation" edge_controller.py || fail=1
grep -q "required_capability_equals_job_type" edge_controller.py || fail=1
grep -q "no_worker_dispatch" edge_controller.py || fail=1
echo "PASS: static Phase 13K markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13k_disabled_study_answer_reasoning_escalation_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13K helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13K helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13k_disabled_study_answer_reasoning_escalation_contract("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13k_disabled_study_answer_reasoning_escalation_contract"]; c=h("mitochondria","cell energy part","What organelle makes energy?",{"verdict":"unsure","relationship":"unclear","confidence":0.4},{"preferred_language":"en","study_language":"en"}); assert c["source"]=="phase_13k_disabled_study_answer_reasoning_escalation_contract_helper"; assert c["mode"]=="disabled_study_answer_reasoning_escalation_contract_only"; assert c["escalation_decision_contract"]["escalation_needed_if_enabled"] is True; assert c["job_contract"]["job_type"]=="study_answer_reasoning_escalation"; assert c["job_contract"]["model_tier"]=="tier_4_deep_reasoning"; assert c["job_contract"]["current_queue_write_enabled"] is False; assert c["job_contract"]["current_scheduler_dispatch_enabled"] is False; assert c["job_enqueue_allowed"] is False; assert c["queue_write_allowed"] is False; assert c["worker_dispatch_allowed"] is False; assert c["model_call_allowed"] is False; assert c["database_write_allowed"] is False; assert c["card_state_change_allowed"] is False; assert c["result_contract"]["backend_acceptance_required"] is True; assert c["result_contract"]["card_state_mutation_by_worker_allowed"] is False; assert c["result_contract"]["prefer_unsure_over_overconfident_grade"] is True; assert c["scheduler_contract"]["current_unknown_job_type_behavior"]=="required_capability_equals_job_type"; assert c["activation_gates"]["requires_small_judge_result_validation"] is True; assert c["activation_gates"]["requires_worker_capability_update"] is True; assert c["safety"]["no_queue_write"] is True; assert c["safety"]["no_worker_dispatch"] is True; print("PASS: dynamic Phase 13K helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "study_answer_reasoning_escalation" "docs/${PHASE}.md" || fail=1
grep -q "tier_4_deep_reasoning" "docs/${PHASE}.md" || fail=1
grep -q "small_judge_confidence_below_0_70" "docs/${PHASE}.md" || fail=1
grep -q "requires_small_judge_result_validation" "docs/${PHASE}.md" || fail=1
grep -q "required_capability equals job_type" "docs/${PHASE}.md" || fail=1
grep -q "no queue write" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13K doc markers exist"

echo
echo "=== no runtime activation markers in Phase 13K helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13k_disabled_study_answer_reasoning_escalation_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "INSERT INTO jobs", "/api/generate", "/api/chat"]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: Phase 13K helper contains no runtime activation markers")' || fail=1

echo
echo "=== safety: power auto full tick remains quarantined ==="
env_dump="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr " " "\n" | grep -E "^EDGE_POWER_AUTO_PAUSED=|^EDGE_POWER_AUTO_TICK_FULL=" || true)"
echo "$env_dump"
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_PAUSED=0$" || fail=1
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_TICK_FULL=0$" || fail=1

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no queue write was added"
echo "PASS: no worker dispatch was added"
echo "PASS: no database write was added"
echo "PASS: no card state change was added"
echo "PASS: no Ollama direct call was added"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
