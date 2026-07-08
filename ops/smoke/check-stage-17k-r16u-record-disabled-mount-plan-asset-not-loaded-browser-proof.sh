#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16u-record-disabled-mount-plan-asset-not-loaded-browser-proof"
DOC="docs/${STAGE}.md"
OUT_DIR="docs/smoke/generated/${STAGE}"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT_ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js"
PASS_LINE="PASS_R16T_DISABLED_MOUNT_PLAN_ASSET_NOT_LOADED_NO_UI_NO_BINDING"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"

[ -f "$DOC" ] || { echo "FAIL: R16U doc missing"; exit 1; }
[ -d "$OUT_DIR" ] || { echo "FAIL: R16U evidence dir missing"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: index missing"; exit 1; }
[ -f "$MOUNT_ASSET" ] || { echo "FAIL: mount asset missing"; exit 1; }

grep -Fq "$PASS_LINE" "$DOC" || { echo "FAIL: pass line missing from doc"; exit 1; }
grep -Fq "$MARKER" "$MOUNT_ASSET" || { echo "FAIL: mount marker missing from source asset"; exit 1; }
if grep -Fq "study-card-images-disabled-mount-plan.js" "$INDEX"; then
  echo "FAIL: mount plan should remain not loaded in R16U"
  exit 1
fi
grep -Fq "study-card-images-disabled-html-preview-renderer.js" "$INDEX" || { echo "FAIL: prior disabled html preview renderer load missing"; exit 1; }

grep -R -Fq "$PASS_LINE" "$OUT_DIR" || { echo "FAIL: pass line missing from evidence"; exit 1; }
grep -R -Fq "mount_loaded_by_script=false" "$OUT_DIR" || { echo "FAIL: mount_loaded_by_script=false missing"; exit 1; }
grep -R -Fq "mount_window_present=false" "$OUT_DIR" || { echo "FAIL: mount_window_present=false missing"; exit 1; }
grep -R -Fq "image_related_file_input_count=0" "$OUT_DIR" || { echo "FAIL: image_related_file_input_count=0 missing"; exit 1; }
grep -R -Fq "image_ui_node_count=0" "$OUT_DIR" || { echo "FAIL: image_ui_node_count=0 missing"; exit 1; }

if grep -Eq 'appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$MOUNT_ASSET"; then
  echo "FAIL: forbidden DOM/write/source API found in mount asset"
  exit 1
fi

printf 'PASS %s smoke\n' "$STAGE"
