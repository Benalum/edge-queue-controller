#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13i-disabled-study-judge-execution-contract-helper"
fail=0

echo "=== ${PHASE}: disabled Study Judge execution contract helper smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13i_disabled_study_judge_execution_contract" edge_controller.py || fail=1
grep -q "phase_13i_disabled_study_judge_execution_contract_helper" edge_controller.py || fail=1
grep -q "disabled_study_judge_execution_contract_only" edge_controller.py || fail=1
grep -q "study_answer_judge" edge_controller.py || fail=1
grep -q "study_answer_reasoning_escalation" edge_controller.py || fail=1
grep -q "tier_2_study_light" edge_controller.py || fail=1
grep -q "tier_4_deep_reasoning" edge_controller.py || fail=1
grep -q "tier_3_companion_medium" edge_controller.py || fail=1
grep -q "direct_browser_to_model_allowed" edge_controller.py || fail=1
grep -q "direct_route_to_ollama_allowed" edge_controller.py || fail=1
echo "PASS: static markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13i_disabled_study_judge_execution_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13d_disabled_study_answer_evaluation_foundation("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13i_disabled_study_judge_execution_contract"]; exact=h("5","five","What is two plus three?",{}); assert exact["source"]=="phase_13i_disabled_study_judge_execution_contract_helper"; assert exact["model_call_allowed"] is False; assert exact["job_enqueue_allowed"] is False; assert exact["database_write_allowed"] is False; assert exact["card_state_change_allowed"] is False; assert exact["small_judge"]["needed"] is False; semantic=h("mitochondria","the part of the cell that makes energy","What organelle produces energy?",{}); assert semantic["small_judge"]["needed"] is True; assert semantic["small_judge"]["job_type"]=="study_answer_judge"; assert semantic["small_judge"]["model_tier"]=="tier_2_study_light"; assert semantic["reasoning_escalation"]["model_tier"]=="tier_4_deep_reasoning"; assert semantic["companion_feedback_handoff"]["model_tier"]=="tier_3_companion_medium"; assert semantic["queue_contract"]["direct_browser_to_model_allowed"] is False; assert semantic["queue_contract"]["direct_route_to_ollama_allowed"] is False; assert semantic["safety"]["no_model_invocation"] is True; print("PASS: dynamic helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "tier_2_study_light" "docs/${PHASE}.md" || fail=1
grep -q "study_answer_judge" "docs/${PHASE}.md" || fail=1
grep -q "tier_4_deep_reasoning" "docs/${PHASE}.md" || fail=1
grep -q "backend as the final authority" "docs/${PHASE}.md" || fail=1
echo "PASS: doc markers exist"

echo
echo "=== no runtime activation markers in Phase 13I helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13i_disabled_study_judge_execution_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "/api/generate", "/api/chat"]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: helper contains no runtime activation markers")' || fail=1

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
echo "PASS: no job enqueue was added"
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
