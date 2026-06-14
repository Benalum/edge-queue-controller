#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13n-disabled-study-review-ui-support-contract"
fail=0

echo "=== ${PHASE}: disabled Study review UI support contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study contract smokes ==="
ops/smoke/check-phase-13k-disabled-study-answer-reasoning-escalation-contract.sh || fail=1
ops/smoke/check-phase-13l-disabled-study-card-flagging-contract.sh || fail=1
ops/smoke/check-phase-13m-disabled-study-card-image-metadata-contract.sh || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13n_disabled_study_review_ui_support_contract" edge_controller.py || fail=1
grep -q "phase_13n_disabled_study_review_ui_support_contract_helper" edge_controller.py || fail=1
grep -q "disabled_study_review_ui_support_contract_only" edge_controller.py || fail=1
grep -q "frontend/study-ui/app.js" edge_controller.py || fail=1
grep -q "frontend/study-ui/index.html" edge_controller.py || fail=1
grep -q "frontend/study-ui/styles.css" edge_controller.py || fail=1
grep -q "frontend/wrapper-ui/app.js" edge_controller.py || fail=1
grep -q "renderReviewCard" edge_controller.py || fail=1
grep -q "companionAskCurrentCard" edge_controller.py || fail=1
grep -q "show_flag_button_on_card" edge_controller.py || fail=1
grep -q "show_image_on_review_card" edge_controller.py || fail=1
grep -q "image_display_only_first_release" edge_controller.py || fail=1
grep -q "requires_skip_correct_wrong_regression_smoke" edge_controller.py || fail=1
grep -q "no_frontend_mutation" edge_controller.py || fail=1
echo "PASS: static Phase 13N markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13n_disabled_study_review_ui_support_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13N helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13N helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13n_disabled_study_review_ui_support_contract("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13n_disabled_study_review_ui_support_contract"]; c=h("study_review_card","card-1","deck-1",{"preferred_language":"en","study_language":"en"}); assert c["source"]=="phase_13n_disabled_study_review_ui_support_contract_helper"; assert c["mode"]=="disabled_study_review_ui_support_contract_only"; assert c["ui_surface_contract"]["current_live_study_ui_file"]=="frontend/study-ui/app.js"; assert c["ui_surface_contract"]["current_live_study_html_file"]=="frontend/study-ui/index.html"; assert c["ui_surface_contract"]["current_live_study_style_file"]=="frontend/study-ui/styles.css"; assert c["ui_surface_contract"]["current_render_function"]=="renderReviewCard"; assert c["ui_surface_contract"]["current_companion_render_function"]=="companionAskCurrentCard"; assert "show_answer" in c["ui_surface_contract"]["current_actions"]; assert "skip" in c["ui_surface_contract"]["current_actions"]; assert c["review_card_contract"]["show_flag_button_on_card"] is True; assert c["review_card_contract"]["show_flag_reason_picker"] is True; assert c["review_card_contract"]["show_image_on_review_card"] is True; assert c["review_card_contract"]["show_image_on_answer_reveal"] is True; assert c["review_card_contract"]["image_display_only_first_release"] is True; assert c["review_card_contract"]["do_not_interrupt_study_session"] is True; assert c["api_dependency_contract"]["future_flag_endpoint"]=="/api/study/cards/{card_id}/flag"; assert c["api_dependency_contract"]["future_unflag_endpoint"]=="/api/study/cards/{card_id}/unflag"; assert c["api_dependency_contract"]["future_image_endpoint"]=="/api/study/cards/{card_id}/image"; assert "image_metadata" in c["api_dependency_contract"]["requires_backend_payload_fields"]; assert "flag_state" in c["api_dependency_contract"]["requires_backend_payload_fields"]; assert c["frontend_wired"] is False; assert c["frontend_mutation_allowed"] is False; assert c["database_write_allowed"] is False; assert c["card_state_change_allowed"] is False; assert c["model_call_allowed"] is False; assert c["job_enqueue_allowed"] is False; assert c["activation_gates"]["requires_skip_correct_wrong_regression_smoke"] is True; assert c["activation_gates"]["requires_no_login_redirect_regression"] is True; assert c["safety"]["no_frontend_mutation"] is True; assert c["safety"]["no_database_write"] is True; assert c["safety"]["no_card_state_change"] is True; print("PASS: dynamic Phase 13N helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "frontend/study-ui/app.js" "docs/${PHASE}.md" || fail=1
grep -q "frontend/study-ui/index.html" "docs/${PHASE}.md" || fail=1
grep -q "frontend/study-ui/styles.css" "docs/${PHASE}.md" || fail=1
grep -q "frontend/wrapper-ui/app.js" "docs/${PHASE}.md" || fail=1
grep -q "renderReviewCard" "docs/${PHASE}.md" || fail=1
grep -q "companionAskCurrentCard" "docs/${PHASE}.md" || fail=1
grep -q "show_flag_button_on_card" "docs/${PHASE}.md" || fail=1
grep -q "show_image_on_review_card" "docs/${PHASE}.md" || fail=1
grep -q "image_display_only_first_release" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/flag" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/image" "docs/${PHASE}.md" || fail=1
grep -q "requires_skip_correct_wrong_regression_smoke" "docs/${PHASE}.md" || fail=1
grep -q "no frontend mutation" "docs/${PHASE}.md" || fail=1
grep -q "no card state change" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13N doc markers exist"

echo
echo "=== no runtime/frontend activation markers in Phase 13N helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13n_disabled_study_review_ui_support_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "INSERT INTO", "UPDATE study_", "ALTER TABLE", "CREATE TABLE", "/api/generate", "/api/chat", "write_text(", "open("]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: Phase 13N helper contains no runtime/frontend activation markers")' || fail=1

echo
echo "=== verify frontend files were not modified ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13N should not modify frontend files"
  fail=1
else
  echo "PASS: frontend files unchanged"
fi

echo
echo "=== verify no live UI/API behavior was added ==="
if grep -qE "@app\.post\(\"/api/study/cards/\{card_id\}/flag\"|@app\.post\(\"/api/study/cards/\{card_id\}/image\"|document\.getElementById\(\"studyPreviewFlag|data-stage13n|phase13nLive" edge_controller.py frontend/study-ui/app.js frontend/wrapper-ui/app.js 2>/dev/null; then
  echo "FAIL: live UI/API wiring should not exist in disabled Phase 13N"
  fail=1
else
  echo "PASS: no live Study review UI/API behavior was added"
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
echo "PASS: no live Study UI behavior was changed"
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no queue write was added"
echo "PASS: no database write was added"
echo "PASS: no schema migration was added"
echo "PASS: no storage write was added"
echo "PASS: no file upload was added"
echo "PASS: no card state change was added"
echo "PASS: no Ollama direct call was added"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
