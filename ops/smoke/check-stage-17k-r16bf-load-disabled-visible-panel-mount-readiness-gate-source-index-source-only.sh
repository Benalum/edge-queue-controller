#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
STAGE="stage-17k-r16bf-load-disabled-visible-panel-mount-readiness-gate-source-index-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATE="frontend/wrapper-ui/apc-wrapper-local/privatepages"
CACHE_BUST="stage17k-r16bf-load-disabled-visible-panel-mount-readiness-gate-source-index-source-only-20260708"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_INDEX_LOAD_R16BF_SOURCE_ONLY"
READINESS_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE_SOURCE_ONLY"
fail(){ echo "FAIL: $*" >&2; exit 1; }
echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || fail "missing index"
[ -f "$PRIVATE/study-card-images-disabled-visible-panel-mount-readiness-gate.js" ] || fail "missing mount readiness gate asset"
grep -Fq "$READINESS_MARKER" "$PRIVATE/study-card-images-disabled-visible-panel-mount-readiness-gate.js" || fail "missing R16BE readiness source marker"
grep -Fq "$MARKER" "$INDEX" || fail "missing R16BF index marker"
grep -Fq "study-card-images-disabled-visible-panel-mount-readiness-gate.js?v=$CACHE_BUST" "$INDEX" || fail "missing mount readiness gate script cache bust"
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
readiness_gate = find('study-card-images-disabled-visible-panel-mount-readiness-gate.js')
if not (visible < adapter < dom_template < slot_resolver < mount_controller < safe_mount < readiness_gate):
    raise SystemExit(f'FAIL load order visible={visible} adapter={adapter} dom_template={dom_template} slot_resolver={slot_resolver} mount_controller={mount_controller} safe_mount={safe_mount} readiness_gate={readiness_gate}')
print(f'PASS R16BF source index order visible < adapter < DOM template < slot resolver < mount controller < safe mount executor < readiness gate visible_line={visible} adapter_line={adapter} dom_template_line={dom_template} slot_resolver_line={slot_resolver} mount_controller_line={mount_controller} safe_mount_line={safe_mount} readiness_gate_line={readiness_gate}')
PY
if grep -En '\b(fetch|XMLHttpRequest|sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|addEventListener|dispatchEvent)\b|\.click\s*\(' "$PRIVATE/study-card-images-disabled-visible-panel-mount-readiness-gate.js"; then
  fail "forbidden write/network/file-picker/bind API present in mount readiness gate asset"
fi
echo "PASS $STAGE smoke"
