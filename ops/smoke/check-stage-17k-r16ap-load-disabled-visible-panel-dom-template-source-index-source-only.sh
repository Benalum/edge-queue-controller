#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only"
ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$ROOT/index.html"
TEMPLATE_ASSET="$ROOT/privatepages/study-card-images-disabled-visible-panel-dom-template.js"
CACHE_BUST="stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
INDEX_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_INDEX_LOAD_R16AP_SOURCE_ONLY"
TEMPLATE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY"
printf '=== %s smoke ===\n' "$STAGE"
[ -f "$INDEX" ] || { echo 'FAIL: index missing' >&2; exit 1; }
[ -f "$TEMPLATE_ASSET" ] || { echo 'FAIL: DOM template asset missing' >&2; exit 1; }
grep -q "$TEMPLATE_MARKER" "$TEMPLATE_ASSET" || { echo 'FAIL: DOM template marker missing' >&2; exit 1; }
grep -q "$INDEX_MARKER" "$INDEX" || { echo 'FAIL: R16AP index marker missing' >&2; exit 1; }
python3 - <<'PY' "$INDEX" "$CACHE_BUST"
import sys
from pathlib import Path
index = Path(sys.argv[1])
cache = sys.argv[2]
lines = index.read_text(encoding='utf-8').splitlines()

def positions(needle):
    return [i + 1 for i, line in enumerate(lines) if needle in line]
visible = positions('study-card-images-disabled-visible-panel.js')
adapter = positions('study-card-images-disabled-visible-panel-mount-adapter.js')
template = positions('study-card-images-disabled-visible-panel-dom-template.js')
assert len(visible) == 1, f'visible panel script count must be 1, got {len(visible)}'
assert len(adapter) == 1, f'mount adapter script count must be 1, got {len(adapter)}'
assert len(template) == 1, f'DOM template script count must be 1, got {len(template)}'
assert visible[0] < adapter[0] < template[0], f'expected visible < adapter < template lines, got {visible[0]}, {adapter[0]}, {template[0]}'
line = lines[template[0] - 1]
assert cache in line, 'DOM template script must use R16AP cache bust'
print('PASS R16AP source index order visible < adapter < DOM template')
print(f'visible_line={visible[0]} adapter_line={adapter[0]} dom_template_line={template[0]}')
PY
# Keep this stage source-only: loading the asset must not introduce write/network/storage calls.
if grep -nE 'fetch\s*\(|XMLHttpRequest|indexedDB|localStorage\.|sessionStorage\.|navigator\.storage|createObjectURL|FileReader|sendBeacon|\.submit\s*\(|document\.createElement|appendChild\s*\(|addEventListener\s*\(' "$TEMPLATE_ASSET"; then
  echo 'FAIL: forbidden active runtime API present in DOM template asset' >&2
  exit 1
fi
if grep -nE '/api/study|/api/anki|drive|googleapis|collection\.anki2|apkg|anki2' "$TEMPLATE_ASSET"; then
  echo 'FAIL: forbidden backend/sync/Anki reference present in DOM template asset' >&2
  exit 1
fi
printf 'PASS %s smoke\n' "$STAGE"
