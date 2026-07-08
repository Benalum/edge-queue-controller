#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16w-record-disabled-mount-plan-loaded-browser-proof"
PASS_LINE="PASS_R16V_DISABLED_MOUNT_PLAN_LOADED_NO_UI_NO_BINDING"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js"
DOC="docs/${STAGE}.md"
EVDIR="docs/smoke/generated/${STAGE}"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY"
CACHE_BUST="stage17k-r16v-load-disabled-mount-plan-no-ui-no-binding-20260708"

printf '=== %s smoke ===\n' "$STAGE"
[ -f "$INDEX" ] || { echo 'FAIL: index missing' >&2; exit 1; }
[ -f "$ASSET" ] || { echo 'FAIL: mount plan asset missing' >&2; exit 1; }
[ -f "$DOC" ] || { echo 'FAIL: doc missing' >&2; exit 1; }
[ -d "$EVDIR" ] || { echo 'FAIL: evidence dir missing' >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo 'FAIL: marker missing from asset' >&2; exit 1; }
grep -Fq "study-card-images-disabled-mount-plan.js" "$INDEX" || { echo 'FAIL: index does not load mount plan' >&2; exit 1; }
grep -Fq "$CACHE_BUST" "$INDEX" || { echo 'FAIL: R16V cache bust missing from index' >&2; exit 1; }
grep -R -Fq "$PASS_LINE" "$DOC" "$EVDIR" || { echo 'FAIL: browser proof pass line not recorded' >&2; exit 1; }
grep -R -Fq 'all_assets_ok=true' "$DOC" "$EVDIR" || { echo 'FAIL: all_assets_ok not recorded' >&2; exit 1; }
grep -R -Fq 'all_safety_ok=true' "$DOC" "$EVDIR" || { echo 'FAIL: all_safety_ok not recorded' >&2; exit 1; }
grep -R -Fq 'image_related_file_input_count=0' "$DOC" "$EVDIR" || { echo 'FAIL: image-related file input zero proof not recorded' >&2; exit 1; }
grep -R -Fq 'image_ui_node_count=0' "$DOC" "$EVDIR" || { echo 'FAIL: image UI node zero proof not recorded' >&2; exit 1; }
grep -R -Fq 'safety=docs-only,no-write,no-deploy' "$DOC" "$EVDIR" || { echo 'FAIL: docs-only safety line missing' >&2; exit 1; }
if grep -Eq 'appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  echo 'FAIL: forbidden write/DOM API found in mount plan source' >&2
  exit 1
fi
echo "PASS ${STAGE} smoke"
