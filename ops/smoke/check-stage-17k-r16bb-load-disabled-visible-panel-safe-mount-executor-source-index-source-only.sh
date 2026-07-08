#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
STAGE="stage-17k-r16bb-load-disabled-visible-panel-safe-mount-executor-source-index-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATE="frontend/wrapper-ui/apc-wrapper-local/privatepages"
CACHE_BUST="stage17k-r16bb-load-disabled-visible-panel-safe-mount-executor-source-index-source-only-20260708"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_INDEX_LOAD_R16BB_SOURCE_ONLY"
SAFE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA_SOURCE_ONLY"
fail(){ echo "FAIL: $*" >&2; exit 1; }
echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || fail "missing index"
[ -f "$PRIVATE/study-card-images-disabled-visible-panel-safe-mount-executor.js" ] || fail "missing safe mount executor asset"
grep -q "$SAFE_MARKER" "$PRIVATE/study-card-images-disabled-visible-panel-safe-mount-executor.js" || fail "missing R16BA safe mount source marker"
grep -q "$MARKER" "$INDEX" || fail "missing R16BB index marker"
grep -q "study-card-images-disabled-visible-panel-safe-mount-executor.js?v=$CACHE_BUST" "$INDEX" || fail "missing safe mount executor script cache bust"
python3 - "$INDEX" <<'PY'
import sys
from pathlib import Path
index = Path(sys.argv[1])
lines = index.read_text().splitlines()
def find(name):
    hits = [i + 1 for i, line in enumerate(lines) if name in line]
    if not hits:
        raise SystemExit(f'FAIL missing {name}')
    return hits[-1]
visible = find('study-card-images-disabled-visible-panel.js')
adapter = find('study-card-images-disabled-visible-panel-mount-adapter.js')
dom_template = find('study-card-images-disabled-visible-panel-dom-template.js')
slot_resolver = find('study-card-images-disabled-visible-panel-slot-resolver.js')
mount_controller = find('study-card-images-disabled-visible-panel-mount-controller.js')
safe_mount = find('study-card-images-disabled-visible-panel-safe-mount-executor.js')
if not (visible < adapter < dom_template < slot_resolver < mount_controller < safe_mount):
    raise SystemExit(f'FAIL load order visible={visible} adapter={adapter} dom_template={dom_template} slot_resolver={slot_resolver} mount_controller={mount_controller} safe_mount={safe_mount}')
print(f'PASS R16BB source index order visible < adapter < DOM template < slot resolver < mount controller < safe mount executor visible_line={visible} adapter_line={adapter} dom_template_line={dom_template} slot_resolver_line={slot_resolver} mount_controller_line={mount_controller} safe_mount_line={safe_mount}')
PY
if grep -Eq 'fetch\(|XMLHttpRequest|sendBeacon|indexedDB\.open|localStorage\.|sessionStorage\.|showOpenFilePicker|<input[^>]+type=["'\'' ]?file' "$PRIVATE/study-card-images-disabled-visible-panel-safe-mount-executor.js"; then
  fail "forbidden write/network/file-picker API present in safe mount executor asset"
fi
echo "PASS $STAGE smoke"
