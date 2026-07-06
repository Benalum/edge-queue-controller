#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14w-record-html-preview-renderer-asset-not-loaded-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14w-record-html-preview-renderer-asset-not-loaded-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record HTML Preview Renderer Asset Not Loaded Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R14V_HTML_PREVIEW_RENDERER_ASSET_NOT_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "Corrected page proof" "$DOC"
grep -Fq "profileButtonsPresent true" "$DOC"
grep -Fq "hasVisibleStatusPreview true" "$DOC"

grep -Fq "htmlRendererLoadedByScript false" "$DOC"
grep -Fq "htmlRendererWindowPresent false" "$DOC"
grep -Fq "renderSpecLoadedByScript true" "$DOC"
grep -Fq "renderSpecWindowPresent true" "$DOC"
grep -Fq "viewModelLoadedByScript true" "$DOC"
grep -Fq "viewModelWindowPresent true" "$DOC"

grep -Fq "assetStatus 200" "$DOC"
grep -Fq "assetHasMarker true" "$DOC"
grep -Fq "assetHasPreviewFunction true" "$DOC"
grep -Fq "assetHasPreviewTextFunction true" "$DOC"
grep -Fq "assetHasDisabledFlags true" "$DOC"
grep -Fq "assetHasForbiddenDomOrWriteCode false" "$DOC"

grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "mountReferencesHtmlRenderer false" "$DOC"
grep -Fq "panelReferencesHtmlRenderer false" "$DOC"

grep -Fq "statusStillNoWrite true" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"

grep -Fq "Choose local backup folder" "$DOC"
grep -Fq "Download snapshot" "$DOC"
grep -Fq "Preview backup file" "$DOC"
grep -Fq "Open current backup file" "$DOC"

grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r14w record html preview renderer asset-not-loaded proof smoke"
