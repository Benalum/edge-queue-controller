#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16an-record-disabled-visible-panel-browser-proof"
PROOF_MARKER="PASS_R16AM_DISABLED_VISIBLE_PANEL_LOADED_NO_UI_NO_BINDING"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"

echo "=== ${STAGE} smoke ==="
[[ -f "${DOC}" ]] || { echo "FAIL: missing doc ${DOC}" >&2; exit 1; }
[[ -d "${EVIDENCE_DIR}" ]] || { echo "FAIL: missing evidence dir ${EVIDENCE_DIR}" >&2; exit 1; }
grep -R "${PROOF_MARKER}" "${DOC}" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: browser proof marker missing" >&2; exit 1; }
grep -R "mounted_panel_count=0" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: mounted panel count proof missing" >&2; exit 1; }
grep -R "mounted_panel_file_input_count=0" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: mounted file input count proof missing" >&2; exit 1; }
grep -R "backend_upload=false" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: backend upload false proof missing" >&2; exit 1; }
grep -R "google_drive_sync=false" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: Google Drive sync false proof missing" >&2; exit 1; }
grep -R "anki_mutation=false" "${EVIDENCE_DIR}" >/dev/null || { echo "FAIL: Anki mutation false proof missing" >&2; exit 1; }
bash ops/smoke/check-stage-17k-r16am-deploy-disabled-visible-panel-source-index-no-ui-no-binding.sh >/dev/null
echo "PASS ${STAGE} smoke"
