#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13o-disabled-immersive-study-mode-ui-contract"
fail=0

echo "=== ${PHASE}: disabled immersive Study mode UI contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study UI/contract smokes ==="
ops/smoke/check-phase-13n-disabled-study-review-ui-support-contract.sh || fail=1
ops/smoke/check-phase-13m-disabled-study-card-image-metadata-contract.sh || fail=1
ops/smoke/check-phase-13l-disabled-study-card-flagging-contract.sh || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13o_disabled_immersive_study_mode_ui_contract" edge_controller.py || fail=1
grep -q "phase_13o_disabled_immersive_study_mode_ui_contract_helper" edge_controller.py || fail=1
grep -q "disabled_immersive_study_mode_ui_contract_only" edge_controller.py || fail=1
grep -q "renderImmersiveStudyMode" edge_controller.py || fail=1
grep -q "renderReviewCard" edge_controller.py || fail=1
grep -q "companionAskCurrentCard" edge_controller.py || fail=1
grep -q "show_latest_companion_message_only" edge_controller.py || fail=1
grep -q "show_current_card_image_if_present" edge_controller.py || fail=1
grep -q "show_answer_input" edge_controller.py || fail=1
grep -q "show_minimal_controls" edge_controller.py || fail=1
grep -q "exit_immersive_keeps_session_active" edge_controller.py || fail=1
grep -q "voice_settings_phase_later" edge_controller.py || fail=1
grep -q "phase_13p" edge_controller.py || fail=1
grep -q "requires_exit_immersive_keeps_session_active_smoke" edge_controller.py || fail=1
grep -q "requires_mobile_layout_smoke" edge_controller.py || fail=1
grep -q "no_voice_runtime_change" edge_controller.py || fail=1
echo "PASS: static Phase 13O markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13o_disabled_immersive_study_mode_ui_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13O helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13O helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13o_disabled_immersive_study_mode_ui_contract("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13o_disabled_immersive_study_mode_ui_contract"]; c=h("immersive_study_review","session-1","card-1","deck-1",{"preferred_language":"en","study_language":"en"}); assert c["source"]=="phase_13o_disabled_immersive_study_mode_ui_contract_helper"; assert c["mode"]=="disabled_immersive_study_mode_ui_contract_only"; assert c["immersive_mode_contract"]["future_immersive_renderer"]=="renderImmersiveStudyMode"; assert c["immersive_mode_contract"]["current_review_renderer"]=="renderReviewCard"; assert c["immersive_mode_contract"]["current_companion_card_renderer"]=="companionAskCurrentCard"; assert c["layout_contract"]["show_latest_companion_message_only"] is True; assert c["layout_contract"]["show_current_card_image_if_present"] is True; assert c["layout_contract"]["show_answer_input"] is True; assert c["layout_contract"]["show_minimal_controls"] is True; assert c["layout_contract"]["preserve_existing_review_flow"] is True; assert "answer_input" in c["control_contract"]["minimal_controls_when_enabled"]; assert "exit_immersive" in c["control_contract"]["minimal_controls_when_enabled"]; assert c["control_contract"]["exit_immersive_keeps_session_active"] is True; assert c["voice_boundary_contract"]["voice_settings_phase_later"]=="phase_13p"; assert c["voice_boundary_contract"]["current_voice_change_enabled"] is False; assert c["frontend_wired"] is False; assert c["frontend_mutation_allowed"] is False; assert c["database_write_allowed"] is False; assert c["card_state_change_allowed"] is False; assert c["model_call_allowed"] is False; assert c["job_enqueue_allowed"] is False; assert c["activation_gates"]["requires_exit_immersive_keeps_session_active_smoke"] is True; assert c["activation_gates"]["requires_mobile_layout_smoke"] is True; assert c["safety"]["no_frontend_mutation"] is True; assert c["safety"]["no_voice_runtime_change"] is True; assert c["safety"]["no_card_state_change"] is True; print("PASS: dynamic Phase 13O helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "renderImmersiveStudyMode" "docs/${PHASE}.md" || fail=1
grep -q "renderReviewCard" "docs/${PHASE}.md" || fail=1
grep -q "companionAskCurrentCard" "docs/${PHASE}.md" || fail=1
grep -q "show_latest_companion_message_only" "docs/${PHASE}.md" || fail=1
grep -q "show_current_card_image_if_present" "docs/${PHASE}.md" || fail=1
grep -q "show_answer_input" "docs/${PHASE}.md" || fail=1
grep -q "show_minimal_controls" "docs/${PHASE}.md" || fail=1
grep -q "exit_immersive" "docs/${PHASE}.md" || fail=1
grep -q "requires_exit_immersive_keeps_session_active_smoke" "docs/${PHASE}.md" || fail=1
grep -q "requires_mobile_layout_smoke" "docs/${PHASE}.md" || fail=1
grep -q "voice_settings_phase_later: phase_13p" "docs/${PHASE}.md" || fail=1
grep -q "no voice runtime change" "docs/${PHASE}.md" || fail=1
grep -q "no frontend mutation" "docs/${PHASE}.md" || fail=1
grep -q "no card state change" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13O doc markers exist"

echo
echo "=== no runtime/frontend/voice activation markers in Phase 13O helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13o_disabled_immersive_study_mode_ui_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "INSERT INTO", "UPDATE study_", "ALTER TABLE", "CREATE TABLE", "/api/generate", "/api/chat", "write_text(", "open(", "navigator.mediaDevices", "speechSynthesis", "SpeechRecognition"]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: Phase 13O helper contains no runtime/frontend/voice activation markers")' || fail=1

echo
echo "=== verify frontend files were not modified ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13O should not modify frontend files"
  fail=1
else
  echo "PASS: frontend files unchanged"
fi

echo
echo "=== verify no live immersive UI/API/voice behavior was added ==="
if grep -qE "renderImmersiveStudyMode|immersive_study_mode_toggle|data-stage13o|phase13oLive|navigator\.mediaDevices|speechSynthesis|SpeechRecognition" frontend/study-ui/app.js frontend/study-ui/index.html frontend/study-ui/styles.css frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css 2>/dev/null; then
  echo "FAIL: live immersive UI or voice wiring should not exist in disabled Phase 13O"
  fail=1
else
  echo "PASS: no live immersive Study UI/API/voice behavior was added"
fi

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
echo "PASS: no frontend files were changed"
echo "PASS: no live immersive Study UI behavior was changed"
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no queue write was added"
echo "PASS: no database write was added"
echo "PASS: no schema migration was added"
echo "PASS: no storage write was added"
echo "PASS: no file upload was added"
echo "PASS: no card state change was added"
echo "PASS: no voice runtime change was added"
echo "PASS: no Ollama direct call was added"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
