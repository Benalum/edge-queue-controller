#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16az-record-disabled-visible-panel-mount-controller-browser-proof"
PROOF="PASS_R16AY_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_LOADED_NO_UI_NO_BINDING"
DOC="docs/${STAGE}.md"
PREV_SMOKE="ops/smoke/check-stage-17k-r16ay-deploy-disabled-visible-panel-mount-controller-source-index-no-ui-no-binding.sh"

printf '=== %s smoke ===\n' "$STAGE"

if [ ! -f "$DOC" ]; then
  echo "FAIL: doc missing: $DOC" >&2
  exit 1
fi

if ! grep -Fq "$PROOF" "$DOC"; then
  echo "FAIL: proof marker missing from doc" >&2
  exit 1
fi

for expected in \
  'File picker did not open.' \
  'Image preview did not render.' \
  'IndexedDB write did not happen.' \
  'Backend upload did not happen.' \
  'Google Drive sync did not happen.' \
  'Anki mutation did not happen.' \
  '/api/me` 401 browser console line is expected'; do
  if ! grep -Fq "$expected" "$DOC"; then
    echo "FAIL: expected browser proof assertion missing: $expected" >&2
    exit 1
  fi
done

if [ ! -x "$PREV_SMOKE" ]; then
  echo "FAIL: previous R16AY smoke missing or not executable" >&2
  exit 1
fi
"$PREV_SMOKE" >/dev/null

printf 'PASS %s smoke\n' "$STAGE"
