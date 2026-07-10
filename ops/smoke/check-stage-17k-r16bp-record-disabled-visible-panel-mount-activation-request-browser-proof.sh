#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16bp-record-disabled-visible-panel-mount-activation-request-browser-proof"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
PROOF_MARKER="PASS_R16BO_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_LOADED_NOT_EXECUTED_NO_UI_NO_BINDING"

printf '=== %s smoke ===\n' "$STAGE"

[ -f "$DOC" ] || { echo "FAIL: missing doc $DOC" >&2; exit 1; }
[ -d "$EVIDENCE_DIR" ] || { echo "FAIL: missing evidence dir $EVIDENCE_DIR" >&2; exit 1; }

grep -R -F "$PROOF_MARKER" "$DOC" "$EVIDENCE_DIR" >/dev/null || {
  echo "FAIL: proof marker missing from doc/evidence" >&2
  exit 1
}

grep -R -F 'browser_timestamp=2026-07-10T17:36:50.189Z' "$EVIDENCE_DIR" >/dev/null || {
  echo "FAIL: browser timestamp missing from evidence" >&2
  exit 1
}

for expected in \
  'api_me_401_noise_expected=true' \
  'loaded_by_public_index=true' \
  'mount_activation_request_loaded=true' \
  'mount_activation_request_executed=false' \
  'mounted_panel_count=0' \
  'mounted_panel_file_input_count=0' \
  'file_picker_opened=false' \
  'image_preview_rendered=false' \
  'client_write=false' \
  'indexeddb_write=false' \
  'backup_payload_write=false' \
  'backend_upload=false' \
  'google_drive_sync=false' \
  'anki_mutation=false' \
  'load_order_ok=true'; do
  grep -R -F "$expected" "$EVIDENCE_DIR" >/dev/null || {
    echo "FAIL: expected evidence line missing: $expected" >&2
    exit 1
  }
done

printf 'PASS %s smoke\n' "$STAGE"
