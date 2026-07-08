#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16i-study-card-images-disabled-render-spec-source-only"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY"
SRC_ROOT="frontend/wrapper-ui/apc-wrapper-local"
TARGET="$SRC_ROOT/privatepages/study-card-images-disabled-render-spec.js"
INDEX="$SRC_ROOT/index.html"
DOC="docs/${STAGE}.md"

if [ ! -f "$TARGET" ]; then
  echo "FAIL $STAGE: missing target" >&2
  exit 1
fi
if [ ! -f "$DOC" ]; then
  echo "FAIL $STAGE: missing doc" >&2
  exit 1
fi
if [ ! -f "$INDEX" ]; then
  echo "FAIL $STAGE: missing index" >&2
  exit 1
fi
if ! grep -Fq "$MARKER" "$TARGET"; then
  echo "FAIL $STAGE: marker missing from target" >&2
  exit 1
fi
if grep -Fq "study-card-images-disabled-render-spec.js" "$INDEX"; then
  echo "FAIL $STAGE: target is loaded by index.html" >&2
  exit 1
fi

for pattern in \
  'document\.' \
  'appendChild' \
  'insertAdjacentElement' \
  'addEventListener("click' \
  "addEventListener('click" \
  'onclick' \
  'fetch(' \
  'XMLHttpRequest' \
  'sendBeacon' \
  'localStorage' \
  'sessionStorage' \
  'indexedDB' \
  'FileReader' \
  'createObjectURL' \
  'showOpenFilePicker' \
  'showSaveFilePicker' \
  'showDirectoryPicker' \
  'createWritable(' \
  '.write(' \
  '.close('; do
  if grep -q "$pattern" "$TARGET"; then
    echo "FAIL $STAGE: forbidden pattern in target: $pattern" >&2
    exit 1
  fi
done

node <<'EOF_NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-render-spec.js');
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY') {
  throw new Error('marker mismatch');
}
if (typeof api.createDisabledRenderSpec !== 'function') throw new Error('missing createDisabledRenderSpec');
if (typeof api.validateDisabledRenderSpec !== 'function') throw new Error('missing validateDisabledRenderSpec');
if (typeof api.getSafetyFlags !== 'function') throw new Error('missing getSafetyFlags');
const spec = api.createDisabledRenderSpec({
  images: {
    question: { id: 'q-img-1', side: 'question', mimeType: 'image/png', byteSize: 1234, altText: 'question diagram' },
    answer: { id: 'a-img-1', side: 'answer', mimeType: 'image/webp', byteSize: 2345, altText: 'answer diagram' }
  }
});
const validation = api.validateDisabledRenderSpec(spec);
if (!validation.ok) throw new Error('validation failed: ' + validation.errors.join('; '));
if (!Array.isArray(spec.slots) || spec.slots.length !== 2) throw new Error('expected two slots');
for (const slot of spec.slots) {
  if (slot.disabled !== true) throw new Error('slot not disabled');
  for (const key of ['mountNow','bindNow','openPickerNow','previewNow','persistNow','uploadNow','mutateAnkiNow']) {
    if (slot[key] !== false) throw new Error(`unsafe slot flag ${slot.side}.${key}`);
  }
}
const safety = api.getSafetyFlags();
for (const key of ['uiMountedNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow']) {
  if (safety[key] !== false) throw new Error(`unsafe safety flag ${key}`);
}
if (safety.sourceOnly !== true) throw new Error('sourceOnly must be true');
console.log('PASS node R16I disabled render spec source-only behavior smoke');
EOF_NODE

echo "PASS $STAGE smoke"
