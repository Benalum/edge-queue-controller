#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16l-load-study-card-images-disabled-render-spec-no-ui-no-binding"
ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$ROOT/index.html"
ASSET="$ROOT/privatepages/study-card-images-disabled-render-spec.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY"
CACHE="stage17k-r16l-load-disabled-image-render-spec-no-ui-no-binding-20260708"

echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || { echo 'FAIL: index missing' >&2; exit 1; }
[ -f "$ASSET" ] || { echo 'FAIL: disabled render spec asset missing' >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo 'FAIL: marker missing from disabled render spec asset' >&2; exit 1; }
grep -Fq "/privatepages/study-card-images-disabled-render-spec.js?v=$CACHE" "$INDEX" || { echo 'FAIL: R16L disabled render spec script missing from index' >&2; exit 1; }
count="$(grep -F "study-card-images-disabled-render-spec.js" "$INDEX" | wc -l | tr -d ' ')"
[ "$count" = "1" ] || { echo "FAIL: expected exactly one disabled render spec script, got $count" >&2; exit 1; }
for helper in \
  study-card-images-local-only-contract.js \
  study-card-images-local-storage-adapter-contract.js \
  study-card-images-backup-manifest-contract.js \
  study-card-images-card-editor-ui-plan.js; do
  grep -Fq "/privatepages/$helper?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX" || {
    echo "FAIL: expected R16G helper script missing: $helper" >&2
    exit 1
  }
done
if grep -E 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET" >/dev/null; then
  echo 'FAIL: disabled render spec contains forbidden DOM/write/network APIs' >&2
  exit 1
fi
echo "PASS $STAGE smoke"
