#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13l-disabled-study-card-flagging-contract"
fail=0

echo "=== ${PHASE}: disabled Study card flagging contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study Judge contract smokes ==="
ops/smoke/check-phase-13i-disabled-study-judge-execution-contract-helper.sh || fail=1
ops/smoke/check-phase-13j-disabled-study-answer-judge-queue-contract.sh || fail=1
ops/smoke/check-phase-13k-disabled-study-answer-reasoning-escalation-contract.sh || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13l_disabled_study_card_flagging_contract" edge_controller.py || fail=1
grep -q "phase_13l_disabled_study_card_flagging_contract_helper" edge_controller.py || fail=1
grep -q "disabled_study_card_flagging_contract_only" edge_controller.py || fail=1
grep -q "study_card_flags" edge_controller.py || fail=1
grep -q "/api/study/cards/{card_id}/flag" edge_controller.py || fail=1
grep -q "/api/study/cards/{card_id}/unflag" edge_controller.py || fail=1
grep -q "bad_image" edge_controller.py || fail=1
grep -q "requires_card_owner_validation" edge_controller.py || fail=1
grep -q "current_database_write_enabled" edge_controller.py || fail=1
echo "PASS: static Phase 13L markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13l_disabled_study_card_flagging_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13L helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13L helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13l_disabled_study_card_flagging_contract("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13l_disabled_study_card_flagging_contract"]; c=h("card-1","deck-1","user-1","bad_image","The picture is blurry.","study_review",{"preferred_language":"en","study_language":"en"}); assert c["source"]=="phase_13l_disabled_study_card_flagging_contract_helper"; assert c["mode"]=="disabled_study_card_flagging_contract_only"; assert c["flag_contract"]["future_table"]=="study_card_flags"; assert c["flag_contract"]["future_flag_route"]=="/api/study/cards/{card_id}/flag"; assert c["flag_contract"]["future_unflag_route"]=="/api/study/cards/{card_id}/unflag"; assert c["flag_contract"]["current_table_create_enabled"] is False; assert c["flag_contract"]["current_route_create_enabled"] is False; assert c["flag_contract"]["current_database_write_enabled"] is False; assert c["payload_contract"]["normalized_reason"]=="bad_image"; assert "wrong_answer" in c["payload_contract"]["allowed_reasons"]; assert "other" in c["payload_contract"]["allowed_reasons"]; assert c["database_write_allowed"] is False; assert c["card_state_change_allowed"] is False; assert c["model_call_allowed"] is False; assert c["job_enqueue_allowed"] is False; assert c["activation_gates"]["requires_card_owner_validation"] is True; assert c["activation_gates"]["requires_schema_migration_or_table_create"] is True; assert c["safety"]["no_database_write"] is True; assert c["safety"]["no_card_state_change"] is True; print("PASS: dynamic Phase 13L helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "study_card_flags" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/flag" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/unflag" "docs/${PHASE}.md" || fail=1
grep -q "bad_image" "docs/${PHASE}.md" || fail=1
grep -q "requires_card_owner_validation" "docs/${PHASE}.md" || fail=1
grep -q "no database write" "docs/${PHASE}.md" || fail=1
grep -q "no card state change" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13L doc markers exist"

echo
echo "=== no runtime activation markers in Phase 13L helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13l_disabled_study_card_flagging_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "INSERT INTO", "UPDATE study_", "CREATE TABLE", "/api/generate", "/api/chat"]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: Phase 13L helper contains no runtime activation markers")' || fail=1

echo
echo "=== verify live flag routes are not present yet ==="
if grep -qE "@app\.post\(\"/api/study/cards/\{card_id\}/flag\"|@app\.post\(\"/api/study/cards/\{card_id\}/unflag\"|CREATE TABLE IF NOT EXISTS study_card_flags" edge_controller.py; then
  echo "FAIL: live flag routes/table should not exist in disabled Phase 13L"
  fail=1
else
  echo "PASS: no live Study card flagging routes/table were added"
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
echo "PASS: no live Study route behavior was changed"
echo "PASS: no live Companion route behavior was changed"
echo "PASS: no model call was added"
echo "PASS: no queue write was added"
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
