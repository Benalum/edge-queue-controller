#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16k-record-disabled-render-spec-asset-not-loaded-browser-proof"
GEN_DIR="docs/smoke/generated/${STAGE}"
DOC="docs/${STAGE}.md"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-render-spec.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY"
PROOF="PASS_R16J_DISABLED_RENDER_SPEC_ASSET_NOT_LOADED_NO_UI_NO_BINDING"

printf '=== %s smoke ===\n' "${STAGE}"
[ -f "${DOC}" ] || { echo "FAIL missing doc" >&2; exit 1; }
[ -f "${ASSET}" ] || { echo "FAIL missing disabled render spec asset" >&2; exit 1; }
[ -f "${INDEX}" ] || { echo "FAIL missing index" >&2; exit 1; }
grep -Fq "${MARKER}" "${ASSET}" || { echo "FAIL marker missing from disabled render spec asset" >&2; exit 1; }
! grep -Fq 'study-card-images-disabled-render-spec.js' "${INDEX}" || { echo "FAIL disabled render spec is loaded by index" >&2; exit 1; }
grep -R -Fq "${PROOF}" "${GEN_DIR}" || { echo "FAIL proof marker missing from generated evidence" >&2; exit 1; }
grep -R -Fq 'disabled_loaded_by_script=false' "${GEN_DIR}" || { echo "FAIL disabled loaded-by-script proof missing" >&2; exit 1; }
grep -R -Fq 'disabled_window_present=false' "${GEN_DIR}" || { echo "FAIL disabled window-present proof missing" >&2; exit 1; }
grep -R -Fq 'image_related_file_input_count=0' "${GEN_DIR}" || { echo "FAIL image-related input proof missing" >&2; exit 1; }
grep -R -Fq 'image_ui_node_count=0' "${GEN_DIR}" || { echo "FAIL image UI node proof missing" >&2; exit 1; }
grep -R -Fq 'safety=docs-only,no-write,no-deploy' "${GEN_DIR}" || { echo "FAIL safety proof missing" >&2; exit 1; }
echo "PASS ${STAGE} smoke"
