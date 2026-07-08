#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
STAGE="stage-17k-r16bj-load-disabled-visible-panel-dom-mount-candidate-source-index-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATE="frontend/wrapper-ui/apc-wrapper-local/privatepages"
CACHE_BUST="stage17k-r16bj-load-disabled-visible-panel-dom-mount-candidate-source-index-source-only-20260708"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_INDEX_LOAD_R16BJ_SOURCE_ONLY"
DOM_MOUNT_CANDIDATE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI_SOURCE_ONLY"
fail(){ echo "FAIL: $*" >&2; exit 1; }
echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || fail "missing index"
[ -f "$PRIVATE/study-card-images-disabled-visible-panel-dom-mount-candidate.js" ] || fail "missing DOM mount candidate asset"
grep -Fq "$DOM_MOUNT_CANDIDATE_MARKER" "$PRIVATE/study-card-images-disabled-visible-panel-dom-mount-candidate.js" || fail "missing R16BI DOM mount candidate source marker"
grep -Fq "$MARKER" "$INDEX" || fail "missing R16BJ index marker"
grep -Fq "study-card-images-disabled-visible-panel-dom-mount-candidate.js?v=$CACHE_BUST" "$INDEX" || fail "missing DOM mount candidate script cache bust"
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
dom_mount_candidate = find('study-card-images-disabled-visible-panel-dom-mount-candidate.js')
if not (visible < adapter < dom_template < slot_resolver < mount_controller < safe_mount < readiness_gate < dom_mount_candidate):
    raise SystemExit(f'FAIL load order visible={visible} adapter={adapter} dom_template={dom_template} slot_resolver={slot_resolver} mount_controller={mount_controller} safe_mount={safe_mount} readiness_gate={readiness_gate} dom_mount_candidate={dom_mount_candidate}')
print(f'PASS R16BJ source index order visible < adapter < DOM template < slot resolver < mount controller < safe mount executor < readiness gate < DOM mount candidate visible_line={visible} adapter_line={adapter} dom_template_line={dom_template} slot_resolver_line={slot_resolver} mount_controller_line={mount_controller} safe_mount_line={safe_mount} readiness_gate_line={readiness_gate} dom_mount_candidate_line={dom_mount_candidate}')
PY
if grep -En '\b(fetch|XMLHttpRequest|sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|addEventListener|dispatchEvent|appendChild|replaceChildren|insertAdjacentHTML)\b|\.click\s*\(' "$PRIVATE/study-card-images-disabled-visible-panel-dom-mount-candidate.js"; then
  fail "forbidden write/network/file-picker/bind/mount API present in DOM mount candidate asset"
fi
echo "PASS $STAGE smoke"
