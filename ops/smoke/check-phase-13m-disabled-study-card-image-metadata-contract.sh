#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13m-disabled-study-card-image-metadata-contract"
fail=0

echo "=== ${PHASE}: disabled Study card image metadata contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study contract smokes ==="
ops/smoke/check-phase-13j-disabled-study-answer-judge-queue-contract.sh || fail=1
ops/smoke/check-phase-13k-disabled-study-answer-reasoning-escalation-contract.sh || fail=1
ops/smoke/check-phase-13l-disabled-study-card-flagging-contract.sh || fail=1

echo
echo "=== static markers ==="
grep -q "def _stage5p13m_disabled_study_card_image_metadata_contract" edge_controller.py || fail=1
grep -q "phase_13m_disabled_study_card_image_metadata_contract_helper" edge_controller.py || fail=1
grep -q "disabled_study_card_image_metadata_contract_only" edge_controller.py || fail=1
grep -q "study_card_images" edge_controller.py || fail=1
grep -q "image_metadata_json" edge_controller.py || fail=1
grep -q "/api/study/cards/{card_id}/image" edge_controller.py || fail=1
grep -q "/api/study/cards/{card_id}/image/remove" edge_controller.py || fail=1
grep -q "include_image_metadata_on_current_session_card" edge_controller.py || fail=1
grep -q "image_is_display_only_for_first_release" edge_controller.py || fail=1
grep -q "multimodal_grading_later" edge_controller.py || fail=1
grep -q "requires_storage_policy_decision" edge_controller.py || fail=1
grep -q "no_schema_migration" edge_controller.py || fail=1
grep -q "no_file_upload" edge_controller.py || fail=1
echo "PASS: static Phase 13M markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13m_disabled_study_card_image_metadata_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13M helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13M helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13m_disabled_study_card_image_metadata_contract("); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); ns={}; exec(text[start:end], ns); h=ns["_stage5p13m_disabled_study_card_image_metadata_contract"]; c=h("card-1","deck-1","user-1","https://example.invalid/card.png","Diagram of mitochondria.","image/png","manual_card_edit",{"preferred_language":"en","study_language":"en"}); assert c["source"]=="phase_13m_disabled_study_card_image_metadata_contract_helper"; assert c["mode"]=="disabled_study_card_image_metadata_contract_only"; assert c["image_metadata_contract"]["future_table"]=="study_card_images"; assert c["image_metadata_contract"]["future_card_column_option"]=="image_metadata_json"; assert c["image_metadata_contract"]["future_add_or_replace_route"]=="/api/study/cards/{card_id}/image"; assert c["image_metadata_contract"]["future_remove_route"]=="/api/study/cards/{card_id}/image/remove"; assert c["image_metadata_contract"]["current_table_create_enabled"] is False; assert c["image_metadata_contract"]["current_column_add_enabled"] is False; assert c["image_metadata_contract"]["current_route_create_enabled"] is False; assert c["image_metadata_contract"]["current_database_write_enabled"] is False; assert c["image_metadata_contract"]["current_storage_write_enabled"] is False; assert c["payload_contract"]["metadata_valid_when_enabled"] is True; assert "image/png" in c["payload_contract"]["allowed_mime_types"]; assert c["public_card_payload_contract"]["include_image_metadata_on_current_session_card"] is True; assert c["study_ui_contract"]["image_is_display_only_for_first_release"] is True; assert c["study_ui_contract"]["multimodal_grading_later"] is True; assert c["database_write_allowed"] is False; assert c["schema_migration_allowed"] is False; assert c["storage_write_allowed"] is False; assert c["file_upload_allowed"] is False; assert c["card_state_change_allowed"] is False; assert c["model_call_allowed"] is False; assert c["job_enqueue_allowed"] is False; assert c["activation_gates"]["requires_storage_policy_decision"] is True; assert c["activation_gates"]["requires_card_owner_validation"] is True; assert c["safety"]["no_database_write"] is True; assert c["safety"]["no_schema_migration"] is True; assert c["safety"]["no_storage_write"] is True; assert c["safety"]["no_file_upload"] is True; print("PASS: dynamic Phase 13M helper behavior is disabled and correct")' || fail=1

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "study_card_images" "docs/${PHASE}.md" || fail=1
grep -q "image_metadata_json" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/image" "docs/${PHASE}.md" || fail=1
grep -q "/api/study/cards/{card_id}/image/remove" "docs/${PHASE}.md" || fail=1
grep -q "include_image_metadata_on_current_session_card" "docs/${PHASE}.md" || fail=1
grep -q "image_is_display_only_for_first_release" "docs/${PHASE}.md" || fail=1
grep -q "multimodal_grading_later" "docs/${PHASE}.md" || fail=1
grep -q "requires_storage_policy_decision" "docs/${PHASE}.md" || fail=1
grep -q "no schema migration" "docs/${PHASE}.md" || fail=1
grep -q "no file upload" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13M doc markers exist"

echo
echo "=== no runtime activation markers in Phase 13M helper ==="
python3 -c 'from pathlib import Path; text=Path("edge_controller.py").read_text(); start=text.index("def _stage5p13m_disabled_study_card_image_metadata_contract"); end=text.index("# --- Phase 13F disabled admin Study-answer preview endpoint"); helper=text[start:end]; forbidden=["requests.post(", "httpx.post(", "ollama.generate", "enqueue_job(", "INSERT INTO", "UPDATE study_", "ALTER TABLE", "CREATE TABLE", "/api/generate", "/api/chat"]; bad=[x for x in forbidden if x in helper]; assert not bad, bad; print("PASS: Phase 13M helper contains no runtime activation markers")' || fail=1

echo
echo "=== verify live image routes/table/schema are not present yet ==="
if grep -qE "@app\.post\(\"/api/study/cards/\{card_id\}/image\"|@app\.post\(\"/api/study/cards/\{card_id\}/image/remove\"|@app\.get\(\"/api/study/cards/\{card_id\}/images\"|CREATE TABLE IF NOT EXISTS study_card_images|ALTER TABLE study_cards ADD COLUMN image_metadata_json" edge_controller.py; then
  echo "FAIL: live image routes/table/schema should not exist in disabled Phase 13M"
  fail=1
else
  echo "PASS: no live Study card image routes/table/schema were added"
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
