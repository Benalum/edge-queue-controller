#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
VISIBLE="$FRONTEND/privatepages/study-card-images-disabled-visible-panel.js"
ADAPTER="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"
DOM_TEMPLATE="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-dom-template.js"
SLOT_RESOLVER="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js"
CACHE="stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708"
VISIBLE_CACHE="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
DOM_TEMPLATE_CACHE="stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_INDEX_LOAD_R16AT_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
for p in "$INDEX" "$VISIBLE" "$ADAPTER" "$DOM_TEMPLATE" "$SLOT_RESOLVER"; do
  [ -f "$p" ] || { echo "FAIL: missing $p"; exit 1; }
done

grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY' "$VISIBLE" || { echo 'FAIL: visible source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY' "$ADAPTER" || { echo 'FAIL: adapter source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY' "$DOM_TEMPLATE" || { echo 'FAIL: DOM template source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY' "$SLOT_RESOLVER" || { echo 'FAIL: slot resolver source marker missing'; exit 1; }
grep -q "$MARKER" "$INDEX" || { echo 'FAIL: R16AT index marker missing'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-slot-resolver.js?v=${CACHE}" "$INDEX" || { echo 'FAIL: slot resolver script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel.js?v=${VISIBLE_CACHE}" "$INDEX" || { echo 'FAIL: visible panel script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-mount-adapter.js?v=${VISIBLE_CACHE}" "$INDEX" || { echo 'FAIL: adapter script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-dom-template.js?v=${DOM_TEMPLATE_CACHE}" "$INDEX" || { echo 'FAIL: DOM template script/cache bust missing from index'; exit 1; }

python3 - "$INDEX" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text().splitlines()
def first(name):
    for i, line in enumerate(text, 1):
        if name in line:
            return i
    raise SystemExit(f'FAIL: missing {name}')
visible = first('study-card-images-disabled-visible-panel.js')
adapter = first('study-card-images-disabled-visible-panel-mount-adapter.js')
dom = first('study-card-images-disabled-visible-panel-dom-template.js')
slot = first('study-card-images-disabled-visible-panel-slot-resolver.js')
if not (visible < adapter < dom < slot):
    raise SystemExit(f'FAIL: expected visible < adapter < dom template < slot resolver, got visible={visible} adapter={adapter} dom={dom} slot={slot}')
print(f'PASS R16AT source index order visible < adapter < DOM template < slot resolver visible_line={visible} adapter_line={adapter} dom_template_line={dom} slot_resolver_line={slot}')
PY

# The slot resolver stage must not introduce active browser writes/network/open-file actions.
if grep -Eq '\b(fetch|XMLHttpRequest|indexedDB|showOpenFilePicker|FileReader|createObjectURL)\b|\.setItem\s*\(|\.put\s*\(|\.add\s*\(' "$SLOT_RESOLVER"; then
  echo 'FAIL: forbidden active write/network/file API text present in slot resolver asset'
  exit 1
fi

echo "PASS ${STAGE} smoke"
