#!/usr/bin/env bash
set -euo pipefail
STATIC_ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="${STATIC_ROOT}/index.html"
VISIBLE_ASSET="${STATIC_ROOT}/privatepages/study-card-images-disabled-visible-panel.js"
ADAPTER_ASSET="${STATIC_ROOT}/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"
VISIBLE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY"
ADAPTER_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY"
CACHE_BUST="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
VISIBLE_SCRIPT="/privatepages/study-card-images-disabled-visible-panel.js?v=${CACHE_BUST}"
ADAPTER_SCRIPT="/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js?v=${CACHE_BUST}"

echo "=== stage-17k-r16am-deploy-disabled-visible-panel-source-index-no-ui-no-binding smoke ==="
[ -f "$INDEX" ] || { echo "FAIL: index missing"; exit 1; }
[ -f "$VISIBLE_ASSET" ] || { echo "FAIL: visible asset missing"; exit 1; }
[ -f "$ADAPTER_ASSET" ] || { echo "FAIL: adapter asset missing"; exit 1; }
grep -Fq "$VISIBLE_MARKER" "$VISIBLE_ASSET" || { echo "FAIL: visible marker missing"; exit 1; }
grep -Fq "$ADAPTER_MARKER" "$ADAPTER_ASSET" || { echo "FAIL: adapter marker missing"; exit 1; }
grep -Fq "$VISIBLE_SCRIPT" "$INDEX" || { echo "FAIL: visible script missing from index"; exit 1; }
grep -Fq "$ADAPTER_SCRIPT" "$INDEX" || { echo "FAIL: adapter script missing from index"; exit 1; }
visible_line="$(grep -nF "$VISIBLE_SCRIPT" "$INDEX" | head -1 | cut -d: -f1 || true)"
adapter_line="$(grep -nF "$ADAPTER_SCRIPT" "$INDEX" | head -1 | cut -d: -f1 || true)"
[ -n "$visible_line" ] || { echo "FAIL: visible line missing"; exit 1; }
[ -n "$adapter_line" ] || { echo "FAIL: adapter line missing"; exit 1; }
[ "$visible_line" -lt "$adapter_line" ] || { echo "FAIL: visible must load before adapter"; exit 1; }

for f in "$VISIBLE_ASSET" "$ADAPTER_ASSET"; do
  if grep -E 'fetch\(|XMLHttpRequest|sendBeacon|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(|indexedDB\.open|localStorage\.setItem|sessionStorage\.setItem' "$f" >/dev/null 2>&1; then
    echo "FAIL: forbidden write/upload API found in $f"
    exit 1
  fi
done

echo "PASS stage-17k-r16am-deploy-disabled-visible-panel-source-index-no-ui-no-binding smoke"
