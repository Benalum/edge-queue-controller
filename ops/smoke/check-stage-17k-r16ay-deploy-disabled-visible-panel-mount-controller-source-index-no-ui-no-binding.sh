#!/usr/bin/env bash
set -euo pipefail
set +H

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
VISIBLE_CACHE="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
DOM_TEMPLATE_CACHE="stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
SLOT_RESOLVER_CACHE="stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708"
MOUNT_CONTROLLER_CACHE="stage17k-r16ax-load-disabled-visible-panel-mount-controller-source-index-source-only-20260708"

visible_line="$(grep -nF "study-card-images-disabled-visible-panel.js?v=${VISIBLE_CACHE}" "$INDEX" | head -1 | cut -d: -f1 || true)"
adapter_line="$(grep -nF "study-card-images-disabled-visible-panel-mount-adapter.js?v=${VISIBLE_CACHE}" "$INDEX" | head -1 | cut -d: -f1 || true)"
dom_template_line="$(grep -nF "study-card-images-disabled-visible-panel-dom-template.js?v=${DOM_TEMPLATE_CACHE}" "$INDEX" | head -1 | cut -d: -f1 || true)"
slot_resolver_line="$(grep -nF "study-card-images-disabled-visible-panel-slot-resolver.js?v=${SLOT_RESOLVER_CACHE}" "$INDEX" | head -1 | cut -d: -f1 || true)"
mount_controller_line="$(grep -nF "study-card-images-disabled-visible-panel-mount-controller.js?v=${MOUNT_CONTROLLER_CACHE}" "$INDEX" | head -1 | cut -d: -f1 || true)"

[[ -n "$visible_line" && -n "$adapter_line" && -n "$dom_template_line" && -n "$slot_resolver_line" && -n "$mount_controller_line" ]] || {
  echo "FAIL: source index missing one or more disabled visible panel script lines"
  exit 1
}

if ! [[ "$visible_line" -lt "$adapter_line" && "$adapter_line" -lt "$dom_template_line" && "$dom_template_line" -lt "$slot_resolver_line" && "$slot_resolver_line" -lt "$mount_controller_line" ]]; then
  echo "FAIL: source index order invalid for disabled visible panel stack"
  exit 1
fi

grep -qF "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY" \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-controller.js || {
  echo "FAIL: mount controller marker missing"
  exit 1
}

if grep -RE "showOpenFilePicker|showSaveFilePicker|indexedDB\.open|fetch\([^)]*api/study|navigator\.storage|getFileHandle\(|createWritable\(|\.write\(|\.close\(|addEventListener\(['\"]click|onclick" \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-controller.js >/tmp/r16ay-forbidden.txt 2>/dev/null; then
  echo "FAIL: forbidden active write/bind API in mount controller"
  cat /tmp/r16ay-forbidden.txt
  exit 1
fi

echo "PASS stage-17k-r16ay-deploy-disabled-visible-panel-mount-controller-source-index-no-ui-no-binding smoke"
