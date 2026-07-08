#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16av-record-disabled-visible-panel-slot-resolver-browser-proof"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
DOC_FILE="docs/${STAGE}.md"
R16AU_SMOKE="ops/smoke/check-stage-17k-r16au-deploy-disabled-visible-panel-slot-resolver-source-index-no-ui-no-binding.sh"
PROOF_MARKER="PASS_R16AU_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_LOADED_NO_UI_NO_BINDING"

printf '=== %s smoke ===\n' "$STAGE"

[[ -d "$EVIDENCE_DIR" ]] || { echo "FAIL: missing evidence dir" >&2; exit 1; }
[[ -f "$DOC_FILE" ]] || { echo "FAIL: missing doc" >&2; exit 1; }
[[ -x "$R16AU_SMOKE" ]] || { echo "FAIL: missing R16AU smoke" >&2; exit 1; }

bash "$R16AU_SMOKE" >/tmp/r16av-r16au-smoke.$$ 2>&1 || {
  cat /tmp/r16av-r16au-smoke.$$ >&2
  rm -f /tmp/r16av-r16au-smoke.$$
  exit 1
}
rm -f /tmp/r16av-r16au-smoke.$$

grep -Rqs "$PROOF_MARKER" "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: browser proof marker missing from R16AV evidence/doc" >&2
  exit 1
}

grep -Rqs 'mounted_panel_count=0' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: mounted panel count proof missing" >&2
  exit 1
}

grep -Rqs 'mounted_panel_file_input_count=0' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: mounted panel file input count proof missing" >&2
  exit 1
}

grep -Rqs 'file_picker_opened=false' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: file picker safety proof missing" >&2
  exit 1
}

grep -Rqs 'image_preview_rendered=false' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: preview safety proof missing" >&2
  exit 1
}

grep -Rqs 'backend_upload=false' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: backend upload safety proof missing" >&2
  exit 1
}

grep -Rqs 'google_drive_sync=false' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: Google Drive safety proof missing" >&2
  exit 1
}

grep -Rqs 'anki_mutation=false' "$EVIDENCE_DIR" "$DOC_FILE" || {
  echo "FAIL: Anki mutation safety proof missing" >&2
  exit 1
}

printf 'PASS %s smoke\n' "$STAGE"
