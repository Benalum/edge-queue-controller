#!/usr/bin/env bash
set -euo pipefail
stage="stage-17k-r16bg-deploy-disabled-visible-panel-mount-readiness-gate-source-index-no-ui-no-binding"
root="frontend/wrapper-ui/apc-wrapper-local"
index="$root/index.html"
visible="study-card-images-disabled-visible-panel.js?v=stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
adapter="study-card-images-disabled-visible-panel-mount-adapter.js?v=stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
dom="study-card-images-disabled-visible-panel-dom-template.js?v=stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
slot="study-card-images-disabled-visible-panel-slot-resolver.js?v=stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708"
mount="study-card-images-disabled-visible-panel-mount-controller.js?v=stage17k-r16ax-load-disabled-visible-panel-mount-controller-source-index-source-only-20260708"
safe="study-card-images-disabled-visible-panel-safe-mount-executor.js?v=stage17k-r16bb-load-disabled-visible-panel-safe-mount-executor-source-index-source-only-20260708"
ready="study-card-images-disabled-visible-panel-mount-readiness-gate.js?v=stage17k-r16bf-load-disabled-visible-panel-mount-readiness-gate-source-index-source-only-20260708"
line_of() {
  python3 - "$index" "$1" <<'PY'
from pathlib import Path
import sys
for i, line in enumerate(Path(sys.argv[1]).read_text(encoding='utf-8').splitlines(), 1):
    if sys.argv[2] in line:
        print(i)
        raise SystemExit(0)
print(0)
PY
}
count_of() {
  python3 - "$index" "$1" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).read_text(encoding='utf-8').count(sys.argv[2]))
PY
}
[ -f "$index" ] || { echo "FAIL missing index" >&2; exit 1; }
for n in "$visible" "$adapter" "$dom" "$slot" "$mount" "$safe" "$ready"; do
  [ "$(count_of "$n")" = "1" ] || { echo "FAIL expected one index entry for $n" >&2; exit 1; }
done
vl=$(line_of "$visible"); al=$(line_of "$adapter"); dl=$(line_of "$dom"); sl=$(line_of "$slot"); ml=$(line_of "$mount"); sf=$(line_of "$safe"); rl=$(line_of "$ready")
[ "$vl" -lt "$al" ] && [ "$al" -lt "$dl" ] && [ "$dl" -lt "$sl" ] && [ "$sl" -lt "$ml" ] && [ "$ml" -lt "$sf" ] && [ "$sf" -lt "$rl" ] || { echo "FAIL load order" >&2; exit 1; }
grep -q 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE_SOURCE_ONLY' "$root/privatepages/study-card-images-disabled-visible-panel-mount-readiness-gate.js" || { echo "FAIL readiness marker missing" >&2; exit 1; }
echo "PASS $stage smoke"
