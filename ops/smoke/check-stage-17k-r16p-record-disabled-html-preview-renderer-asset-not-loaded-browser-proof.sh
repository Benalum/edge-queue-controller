#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16p-record-disabled-html-preview-renderer-asset-not-loaded-browser-proof"
PASS_LINE="PASS_R16O_DISABLED_HTML_PREVIEW_RENDERER_ASSET_NOT_LOADED_NO_UI_NO_BINDING"
DOC="docs/$STAGE.md"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-html-preview-renderer.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY"

[ -f "$DOC" ] || { echo "FAIL missing doc"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL missing index"; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL missing source asset"; exit 1; }
grep -Fq "$PASS_LINE" "$DOC" || { echo "FAIL pass line missing from doc"; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL marker missing from source asset"; exit 1; }
if grep -Fq "study-card-images-disabled-html-preview-renderer.js" "$INDEX"; then
  echo "FAIL index loads disabled html preview renderer during asset-not-loaded record"
  exit 1
fi
grep -Fq "No live deploy in this record stage" "$DOC" || { echo "FAIL no-deploy statement missing"; exit 1; }
grep -Fq "No UI mounted" "$DOC" || { echo "FAIL no-ui statement missing"; exit 1; }
grep -Fq "No backend upload" "$DOC" || { echo "FAIL backend safety statement missing"; exit 1; }
grep -Fq "No Anki mutation" "$DOC" || { echo "FAIL Anki safety statement missing"; exit 1; }

echo "PASS $STAGE smoke"
