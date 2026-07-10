#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
STAGE="stage-17k-r16br-load-disabled-visible-panel-controlled-mount-executor-source-index-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATE="frontend/wrapper-ui/apc-wrapper-local/privatepages"
CACHE_BUST="stage17k-r16br-load-disabled-visible-panel-controlled-mount-executor-source-index-source-only-20260710"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_INDEX_LOAD_R16BR_SOURCE_ONLY"
CONTROLLED_MOUNT_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_R16BQ_SOURCE_ONLY"
fail(){ echo "FAIL: $*" >&2; exit 1; }
echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || fail "missing index"
[ -f "$PRIVATE/study-card-images-disabled-visible-panel-controlled-mount-executor.js" ] || fail "missing controlled mount executor asset"
grep -Fq "$CONTROLLED_MOUNT_MARKER" "$PRIVATE/study-card-images-disabled-visible-panel-controlled-mount-executor.js" || fail "missing R16BQ controlled mount executor source marker"
grep -Fq "$MARKER" "$INDEX" || fail "missing R16BR index marker"
grep -Fq "study-card-images-disabled-visible-panel-controlled-mount-executor.js?v=$CACHE_BUST" "$INDEX" || fail "missing controlled mount executor script cache bust"
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
activation_request = find('study-card-images-disabled-visible-panel-mount-activation-request.js')
controlled_mount = find('study-card-images-disabled-visible-panel-controlled-mount-executor.js')
if not (visible < adapter < dom_template < slot_resolver < mount_controller < safe_mount < readiness_gate < dom_mount_candidate < activation_request < controlled_mount):
    raise SystemExit(f'FAIL load order visible={visible} adapter={adapter} dom_template={dom_template} slot_resolver={slot_resolver} mount_controller={mount_controller} safe_mount={safe_mount} readiness_gate={readiness_gate} dom_mount_candidate={dom_mount_candidate} activation_request={activation_request} controlled_mount={controlled_mount}')
print(f'PASS R16BR source index order visible < adapter < DOM template < slot resolver < mount controller < safe mount executor < readiness gate < DOM mount candidate < activation request < controlled mount executor visible_line={visible} adapter_line={adapter} dom_template_line={dom_template} slot_resolver_line={slot_resolver} mount_controller_line={mount_controller} safe_mount_line={safe_mount} readiness_gate_line={readiness_gate} dom_mount_candidate_line={dom_mount_candidate} activation_request_line={activation_request} controlled_mount_line={controlled_mount}')
PY
if grep -En '\b(createElement|appendChild|insertBefore|replaceChildren|removeChild|querySelector|querySelectorAll|getElementById|addEventListener|removeEventListener|dispatchEvent|click|showOpenFilePicker|indexedDB|localStorage|sessionStorage|fetch|XMLHttpRequest|sendBeacon|FormData|FileReader|navigator\.storage)\b' "$PRIVATE/study-card-images-disabled-visible-panel-controlled-mount-executor.js"; then
  fail "forbidden write/network/file-picker/bind/mount API present in controlled mount executor asset"
fi
sha256sum "$INDEX" "$PRIVATE/study-card-images-disabled-visible-panel-controlled-mount-executor.js" "$PRIVATE/study-card-images-disabled-visible-panel-mount-activation-request.js"
echo "PASS $STAGE smoke"
