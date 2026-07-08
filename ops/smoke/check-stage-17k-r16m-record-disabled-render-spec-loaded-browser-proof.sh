#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16m-record-disabled-render-spec-loaded-browser-proof"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="${FRONTEND}/index.html"
ASSET="${FRONTEND}/privatepages/study-card-images-disabled-render-spec.js"
DOC="docs/${STAGE}.md"
EVIDENCE_DIR="docs/smoke/generated/${STAGE}"
PROOF="PASS_R16L_DISABLED_RENDER_SPEC_LOADED_NO_UI_NO_BINDING"
LOAD_MARKER="stage17k-r16l-load-disabled-image-render-spec-no-ui-no-binding-20260708"
ASSET_MARKER="APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="

[ -f "$INDEX" ] || { echo "FAIL: missing index"; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL: missing disabled render spec asset"; exit 1; }
[ -f "$DOC" ] || { echo "FAIL: missing doc"; exit 1; }
[ -d "$EVIDENCE_DIR" ] || { echo "FAIL: missing evidence dir"; exit 1; }

grep -Fq "$LOAD_MARKER" "$INDEX" || { echo "FAIL: index does not load R16L disabled render spec"; exit 1; }
grep -Fq "$ASSET_MARKER" "$ASSET" || { echo "FAIL: asset marker missing"; exit 1; }
grep -Fq "$PROOF" "$DOC" || { echo "FAIL: proof not recorded in doc"; exit 1; }
grep -R -Fq "$PROOF" "$EVIDENCE_DIR" || { echo "FAIL: proof not recorded in evidence"; exit 1; }
grep -Fq "No deploy." "$DOC" || { echo "FAIL: docs-only no-deploy boundary missing"; exit 1; }
grep -Fq "No UI mount." "$DOC" || { echo "FAIL: no UI mount boundary missing"; exit 1; }
grep -Fq "No image-related file input." "$DOC" || { echo "FAIL: no image-related input boundary missing"; exit 1; }
grep -Fq "No IndexedDB write." "$DOC" || { echo "FAIL: no IndexedDB write boundary missing"; exit 1; }
grep -Fq "No backend upload." "$DOC" || { echo "FAIL: no backend upload boundary missing"; exit 1; }
grep -Fq "No Anki mutation." "$DOC" || { echo "FAIL: no Anki mutation boundary missing"; exit 1; }

echo "PASS ${STAGE} smoke"
