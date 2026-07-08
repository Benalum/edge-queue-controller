#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16ax-load-disabled-visible-panel-mount-controller-source-index-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
VISIBLE="$FRONTEND/privatepages/study-card-images-disabled-visible-panel.js"
ADAPTER="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"
DOM_TEMPLATE="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-dom-template.js"
SLOT_RESOLVER="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js"
MOUNT_CONTROLLER="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-mount-controller.js"
CACHE="stage17k-r16ax-load-disabled-visible-panel-mount-controller-source-index-source-only-20260708"
VISIBLE_CACHE="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
DOM_TEMPLATE_CACHE="stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
SLOT_RESOLVER_CACHE="stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_INDEX_LOAD_R16AX_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
for p in "$INDEX" "$VISIBLE" "$ADAPTER" "$DOM_TEMPLATE" "$SLOT_RESOLVER" "$MOUNT_CONTROLLER"; do
  [ -f "$p" ] || { echo "FAIL: missing $p"; exit 1; }
done

grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY' "$VISIBLE" || { echo 'FAIL: visible source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY' "$ADAPTER" || { echo 'FAIL: adapter source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY' "$DOM_TEMPLATE" || { echo 'FAIL: DOM template source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY' "$SLOT_RESOLVER" || { echo 'FAIL: slot resolver source marker missing'; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY' "$MOUNT_CONTROLLER" || { echo 'FAIL: mount controller source marker missing'; exit 1; }
grep -q "$MARKER" "$INDEX" || { echo 'FAIL: R16AX index marker missing'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-mount-controller.js?v=${CACHE}" "$INDEX" || { echo 'FAIL: mount controller script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel.js?v=${VISIBLE_CACHE}" "$INDEX" || { echo 'FAIL: visible panel script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-mount-adapter.js?v=${VISIBLE_CACHE}" "$INDEX" || { echo 'FAIL: adapter script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-dom-template.js?v=${DOM_TEMPLATE_CACHE}" "$INDEX" || { echo 'FAIL: DOM template script/cache bust missing from index'; exit 1; }
grep -q "study-card-images-disabled-visible-panel-slot-resolver.js?v=${SLOT_RESOLVER_CACHE}" "$INDEX" || { echo 'FAIL: slot resolver script/cache bust missing from index'; exit 1; }

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
mount = first('study-card-images-disabled-visible-panel-mount-controller.js')
if not (visible < adapter < dom < slot < mount):
    raise SystemExit(f'FAIL: expected visible < adapter < dom template < slot resolver < mount controller, got visible={visible} adapter={adapter} dom={dom} slot={slot} mount={mount}')
print(f'PASS R16AX source index order visible < adapter < DOM template < slot resolver < mount controller visible_line={visible} adapter_line={adapter} dom_template_line={dom} slot_resolver_line={slot} mount_controller_line={mount}')
PY

if grep -Eq '\b(fetch|XMLHttpRequest|WebSocket|navigator\.sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|chooseFileSystemEntries)\b|\.setItem\s*\(|\.put\s*\(|\.add\s*\(' "$MOUNT_CONTROLLER"; then
  echo 'FAIL: forbidden active write/network/file API text present in mount controller asset'
  exit 1
fi

echo "PASS ${STAGE} smoke"
