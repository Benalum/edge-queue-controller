#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
STAGE="stage-17k-r16bc-deploy-disabled-visible-panel-safe-mount-executor-source-index-no-ui-no-binding"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
PP="$FRONTEND/privatepages"
VISIBLE="$PP/study-card-images-disabled-visible-panel.js"
ADAPTER="$PP/study-card-images-disabled-visible-panel-mount-adapter.js"
DOM_TEMPLATE="$PP/study-card-images-disabled-visible-panel-dom-template.js"
SLOT_RESOLVER="$PP/study-card-images-disabled-visible-panel-slot-resolver.js"
MOUNT_CONTROLLER="$PP/study-card-images-disabled-visible-panel-mount-controller.js"
SAFE_MOUNT="$PP/study-card-images-disabled-visible-panel-safe-mount-executor.js"
VISIBLE_CACHE="stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708"
DOM_TEMPLATE_CACHE="stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708"
SLOT_RESOLVER_CACHE="stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708"
MOUNT_CONTROLLER_CACHE="stage17k-r16ax-load-disabled-visible-panel-mount-controller-source-index-source-only-20260708"
SAFE_MOUNT_CACHE="stage17k-r16bb-load-disabled-visible-panel-safe-mount-executor-source-index-source-only-20260708"
for f in "$INDEX" "$VISIBLE" "$ADAPTER" "$DOM_TEMPLATE" "$SLOT_RESOLVER" "$MOUNT_CONTROLLER" "$SAFE_MOUNT"; do
  [[ -f "$f" ]] || { echo "FAIL: missing $f" >&2; exit 1; }
done
visible_line=$(grep -n "study-card-images-disabled-visible-panel.js?v=$VISIBLE_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
adapter_line=$(grep -n "study-card-images-disabled-visible-panel-mount-adapter.js?v=$VISIBLE_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
dom_template_line=$(grep -n "study-card-images-disabled-visible-panel-dom-template.js?v=$DOM_TEMPLATE_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
slot_resolver_line=$(grep -n "study-card-images-disabled-visible-panel-slot-resolver.js?v=$SLOT_RESOLVER_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
mount_controller_line=$(grep -n "study-card-images-disabled-visible-panel-mount-controller.js?v=$MOUNT_CONTROLLER_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
safe_mount_line=$(grep -n "study-card-images-disabled-visible-panel-safe-mount-executor.js?v=$SAFE_MOUNT_CACHE" "$INDEX" | cut -d: -f1 | head -1 || true)
for v in visible_line adapter_line dom_template_line slot_resolver_line mount_controller_line safe_mount_line; do
  [[ -n "${!v}" ]] || { echo "FAIL: missing index line $v" >&2; exit 1; }
done
if ! (( visible_line < adapter_line && adapter_line < dom_template_line && dom_template_line < slot_resolver_line && slot_resolver_line < mount_controller_line && mount_controller_line < safe_mount_line )); then
  echo "FAIL: source index order invalid" >&2
  exit 1
fi
grep -q "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA_SOURCE_ONLY" "$SAFE_MOUNT" || { echo "FAIL: safe mount marker missing" >&2; exit 1; }
if grep -Eq 'showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|indexedDB\.open|fetch\(|XMLHttpRequest|navigator\.storage|document\.createElement\(|appendChild\(|insertAdjacentHTML|addEventListener\(["'"'"']click|onclick|\.write\(|\.put\(|\.add\(|localStorage\.setItem|sessionStorage\.setItem' "$SAFE_MOUNT"; then
  echo "FAIL: forbidden runtime/write API found in safe mount executor source" >&2
  exit 1
fi
echo "PASS $STAGE smoke"
