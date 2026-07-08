#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16al-load-disabled-visible-panel-source-index-source-only"
CACHE_BUST="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
VISIBLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel.js"
ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"
VISIBLE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY"
ADAPTER_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY"
STAGE_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_INDEX_LOAD_R16AL_SOURCE_ONLY"
fail(){ echo "FAIL: $*" >&2; exit 1; }
[ -f "$INDEX" ] || fail "missing $INDEX"
[ -f "$VISIBLE" ] || fail "missing $VISIBLE"
[ -f "$ADAPTER" ] || fail "missing $ADAPTER"
grep -q "$VISIBLE_MARKER" "$VISIBLE" || fail "visible marker missing"
grep -q "$ADAPTER_MARKER" "$ADAPTER" || fail "adapter marker missing"
node --check "$VISIBLE" >/dev/null
node --check "$ADAPTER" >/dev/null
python3 - <<'PY'
from pathlib import Path
import re, sys
index = Path("frontend/wrapper-ui/apc-wrapper-local/index.html").read_text()
visible = "/privatepages/study-card-images-disabled-visible-panel.js?v=stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
adapter = "/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js?v=stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)
if index.count(visible) != 1:
    fail(f"visible panel script count expected 1 got {index.count(visible)}")
if index.count(adapter) != 1:
    fail(f"adapter script count expected 1 got {index.count(adapter)}")
if index.find(visible) > index.find(adapter):
    fail("visible panel script must load before mount adapter")
if index.count("stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708") != 2:
    fail("R16AL cache-bust count must be exactly 2")
for path in [
    Path("frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel.js"),
    Path("frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"),
]:
    text = path.read_text()
    forbidden = {
        "fetch call": r"\bfetch\s*\(",
        "XMLHttpRequest": r"\bXMLHttpRequest\b",
        "showOpenFilePicker call": r"\bshowOpenFilePicker\s*\(",
        "new FileReader": r"\bnew\s+FileReader\b",
        "FileReader call": r"\bFileReader\s*\(",
        "indexedDB property": r"\bindexedDB\s*\.",
        "localStorage property": r"\blocalStorage\s*\.",
        "sessionStorage property": r"\bsessionStorage\s*\.",
        "URL.createObjectURL call": r"\bURL\s*\.\s*createObjectURL\s*\(",
        "Blob constructor": r"\bnew\s+Blob\b|\bBlob\s*\(",
        "APC_LOCAL_SAVE write": r"\bAPC_LOCAL_SAVE\s*\.\s*(setDoc|put|write|delete)",
        "Google sync call": r"\bAPC_GOOGLE_SYNC\s*\.",
        "study backend reference": r"/api/study",
    }
    for label, pattern in forbidden.items():
        if re.search(pattern, text):
            fail(f"forbidden {label} in {path}")
print("PASS R16AL source index load order smoke")
PY
printf 'PASS %s smoke\n' "$STAGE"
