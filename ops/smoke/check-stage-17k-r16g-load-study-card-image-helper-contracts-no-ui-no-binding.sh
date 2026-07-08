#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"

for helper in \
  study-card-images-local-only-contract.js \
  study-card-images-local-storage-adapter-contract.js \
  study-card-images-backup-manifest-contract.js \
  study-card-images-card-editor-ui-plan.js; do
  grep -Fq "/privatepages/$helper?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX"
done

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Load Study Card Image Helper Contracts, No UI/Binding" "$DOC"
grep -Fq "No card editor UI change" "$DOC"
grep -Fq "No file picker" "$DOC"
grep -Fq "No image preview" "$DOC"
grep -Fq "No blob write" "$DOC"
grep -Fq "No IndexedDB write" "$DOC"
grep -Fq "No backup write" "$DOC"
grep -Fq "No backend upload" "$DOC"
grep -Fq "No Google Drive sync" "$DOC"
grep -Fq "No Anki mutation" "$DOC"

grep -Fq "PASS exact script delta old+4 with no removals" "$OUT_DIR/source-check."*.txt
grep -Fq "R16G_VM200_LOAD_STUDY_CARD_IMAGE_HELPER_CONTRACTS_NO_UI_NO_BINDING_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R16G smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r16g load study card image helper contracts no ui/no binding smoke"
