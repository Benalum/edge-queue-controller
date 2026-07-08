#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16bl-record-disabled-visible-panel-dom-mount-candidate-browser-proof"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
PROOF_MARKER="PASS_R16BK_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_LOADED_NOT_EXECUTED_NO_UI_NO_BINDING"
PREV_DEPLOY_SMOKE="ops/smoke/check-stage-17k-r16bk-deploy-disabled-visible-panel-dom-mount-candidate-source-index-no-ui-no-binding.sh"

echo "=== ${STAGE} smoke ==="
[ -f "$DOC" ] || { echo "FAIL: missing doc $DOC"; exit 1; }
[ -d "$EVIDENCE_DIR" ] || { echo "FAIL: missing evidence dir $EVIDENCE_DIR"; exit 1; }
[ -x "$PREV_DEPLOY_SMOKE" ] || { echo "FAIL: missing previous deploy smoke"; exit 1; }

grep -q "$PROOF_MARKER" "$DOC" || { echo "FAIL: proof marker missing from doc"; exit 1; }
grep -R -q "$PROOF_MARKER" "$EVIDENCE_DIR" || { echo "FAIL: proof marker missing from evidence"; exit 1; }
grep -R -q 'dom_mount_candidate_loaded=true' "$EVIDENCE_DIR" || { echo "FAIL: DOM mount candidate loaded proof missing"; exit 1; }
grep -R -q 'dom_mount_candidate_executed=false' "$EVIDENCE_DIR" || { echo "FAIL: DOM mount candidate executed false proof missing"; exit 1; }
grep -R -q 'mounted_panel_count=0' "$EVIDENCE_DIR" || { echo "FAIL: mounted panel count proof missing"; exit 1; }
grep -R -q 'mounted_panel_file_input_count=0' "$EVIDENCE_DIR" || { echo "FAIL: mounted panel file input count proof missing"; exit 1; }
grep -R -q 'client_write=false' "$EVIDENCE_DIR" || { echo "FAIL: client write false proof missing"; exit 1; }
grep -R -q 'indexeddb_write=false' "$EVIDENCE_DIR" || { echo "FAIL: IndexedDB false proof missing"; exit 1; }
grep -R -q 'backup_payload_write=false' "$EVIDENCE_DIR" || { echo "FAIL: backup payload false proof missing"; exit 1; }
grep -R -q 'backend_upload=false' "$EVIDENCE_DIR" || { echo "FAIL: backend upload false proof missing"; exit 1; }
grep -R -q 'google_drive_sync=false' "$EVIDENCE_DIR" || { echo "FAIL: Drive sync false proof missing"; exit 1; }
grep -R -q 'anki_mutation=false' "$EVIDENCE_DIR" || { echo "FAIL: Anki mutation false proof missing"; exit 1; }

echo "PASS ${STAGE} smoke"
