#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16bh-record-disabled-visible-panel-mount-readiness-gate-browser-proof"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
PROOF_MARKER="PASS_R16BG_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_LOADED_NOT_EXECUTED_NO_UI_NO_BINDING"
PREV_DEPLOY_SMOKE="ops/smoke/check-stage-17k-r16bg-deploy-disabled-visible-panel-mount-readiness-gate-source-index-no-ui-no-binding.sh"

echo "=== ${STAGE} smoke ==="
[ -f "$DOC" ] || { echo "FAIL: missing doc $DOC"; exit 1; }
[ -d "$EVIDENCE_DIR" ] || { echo "FAIL: missing evidence dir $EVIDENCE_DIR"; exit 1; }
[ -x "$PREV_DEPLOY_SMOKE" ] || { echo "FAIL: missing previous deploy smoke"; exit 1; }

grep -q "$PROOF_MARKER" "$DOC" || { echo "FAIL: proof marker missing from doc"; exit 1; }
grep -R -q "$PROOF_MARKER" "$EVIDENCE_DIR" || { echo "FAIL: proof marker missing from evidence"; exit 1; }
grep -R -q 'readiness_gate_executed=false' "$EVIDENCE_DIR" || { echo "FAIL: readiness gate executed flag missing"; exit 1; }
grep -R -q 'mounted_panel_count=0' "$EVIDENCE_DIR" || { echo "FAIL: mounted panel count proof missing"; exit 1; }
grep -R -q 'indexeddb_write=false' "$EVIDENCE_DIR" || { echo "FAIL: IndexedDB false proof missing"; exit 1; }
grep -R -q 'backend_upload=false' "$EVIDENCE_DIR" || { echo "FAIL: backend upload false proof missing"; exit 1; }
grep -R -q 'google_drive_sync=false' "$EVIDENCE_DIR" || { echo "FAIL: Drive sync false proof missing"; exit 1; }
grep -R -q 'anki_mutation=false' "$EVIDENCE_DIR" || { echo "FAIL: Anki mutation false proof missing"; exit 1; }

echo "PASS ${STAGE} smoke"
