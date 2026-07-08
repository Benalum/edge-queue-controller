#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16ar-record-disabled-visible-panel-dom-template-browser-proof"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
PREV_SMOKE="ops/smoke/check-stage-17k-r16aq-deploy-disabled-visible-panel-dom-template-source-index-no-ui-no-binding.sh"
PROOF_MARKER="PASS_R16AQ_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_LOADED_NO_UI_NO_BINDING"

echo "=== ${STAGE} smoke ==="
[[ -f "$DOC" ]] || { echo "FAIL: missing doc $DOC" >&2; exit 1; }
[[ -d "$EVIDENCE_DIR" ]] || { echo "FAIL: missing evidence dir $EVIDENCE_DIR" >&2; exit 1; }
[[ -x "$PREV_SMOKE" ]] || { echo "FAIL: missing previous R16AQ smoke" >&2; exit 1; }

grep -q "$PROOF_MARKER" "$DOC" || { echo "FAIL: proof marker missing from doc" >&2; exit 1; }
grep -R -q "$PROOF_MARKER" "$EVIDENCE_DIR" || { echo "FAIL: proof marker missing from evidence" >&2; exit 1; }
grep -R -q 'mounted_panel_count=0' "$EVIDENCE_DIR" || { echo "FAIL: mounted panel count proof missing" >&2; exit 1; }
grep -R -q 'mounted_panel_file_input_count=0' "$EVIDENCE_DIR" || { echo "FAIL: mounted panel file-input count proof missing" >&2; exit 1; }
grep -R -q 'file_picker_opened=false' "$EVIDENCE_DIR" || { echo "FAIL: file picker safety proof missing" >&2; exit 1; }
grep -R -q 'image_preview_rendered=false' "$EVIDENCE_DIR" || { echo "FAIL: preview safety proof missing" >&2; exit 1; }
grep -R -q 'indexeddb_write=false' "$EVIDENCE_DIR" || { echo "FAIL: IndexedDB safety proof missing" >&2; exit 1; }
grep -R -q 'backend_upload=false' "$EVIDENCE_DIR" || { echo "FAIL: backend upload safety proof missing" >&2; exit 1; }
grep -R -q 'google_drive_sync=false' "$EVIDENCE_DIR" || { echo "FAIL: Drive sync safety proof missing" >&2; exit 1; }
grep -R -q 'anki_mutation=false' "$EVIDENCE_DIR" || { echo "FAIL: Anki mutation safety proof missing" >&2; exit 1; }

bash "$PREV_SMOKE" >/dev/null

echo "PASS ${STAGE} smoke"
