#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r16e-deploy-study-card-image-contract-assets-not-loaded.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16e-deploy-study-card-image-contract-assets-not-loaded"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Deploy Study Card Image Contract Assets Not Loaded" "$DOC"
grep -Fq "No index load" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No card editor mount" "$DOC"
grep -Fq "No file picker" "$DOC"
grep -Fq "No IndexedDB write" "$DOC"
grep -Fq "No backup write" "$DOC"
grep -Fq "No backend deploy" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"

for file in \
  study-card-images-local-only-contract.js \
  study-card-images-local-storage-adapter-contract.js \
  study-card-images-backup-manifest-contract.js \
  study-card-images-card-editor-ui-plan.js
  do
    if grep -Fq "/privatepages/$file" "$INDEX"; then
      echo "FAIL: index must not load $file"
      exit 1
    fi
  done

grep -Fq "R16E_VM200_STUDY_CARD_IMAGE_CONTRACT_ASSETS_NOT_LOADED_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R16E smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r16e deploy study card image contract assets not loaded smoke"
