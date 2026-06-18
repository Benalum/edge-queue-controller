#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-ly-ui-legacy-copy-source-patch-no-deploy"
DOC="docs/${PHASE}.md"
APP_SRC="frontend/wrapper-ui/app.js"
LEGACY_RE='ct-101|ct101|CT101|master-laptop|pveso|PVESO|llms-worker|ct101-laptop-queue-worker'

echo "=== smoke: ${PHASE} ==="

require_doc() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing doc pattern: $pattern"
    exit 1
  fi
}

require_doc_any() {
  local label="$1"
  shift
  local pattern
  for pattern in "$@"; do
    if grep -Fq "$pattern" "$DOC"; then
      echo "PASS: ${label}"
      return 0
    fi
  done
  echo "FAIL: missing any accepted doc pattern for ${label}"
  exit 1
}

test -f "$DOC"
test -f "$APP_SRC"

require_doc "Phase 14J-LY"
require_doc "UI Legacy Copy Source Patch, No Deploy"
require_doc "843c93e"
require_doc "controller-phase-14j-lx-ui-legacy-copy-cleanup-plan-no-deploy-2026-06-18"
require_doc "$APP_SRC"
require_doc "post_patch_legacy_hits=absent"
require_doc "PASS_PHASE_14J_LY_UI_LEGACY_COPY_SOURCE_PATCH_NO_DEPLOY_DONE"

require_doc_any "frontend deploy guardrail" "no frontend deploy" "No frontend deploy"
require_doc_any "VM200 write guardrail" "no VM200 write" "No VM200 write"
require_doc_any "qemu guest-agent guardrail" "no qemu guest-agent operation" "No qemu guest-agent operation"
require_doc_any "service restart guardrail" "no service restart/reload/enable/start/stop" "No service restart/reload/enable/start/stop"
require_doc_any "DB restore guardrail" "no DB restore/import/migration" "No DB restore/import/migration"
require_doc_any "storage mutation guardrail" "no storage unlock/mount/format/key/crypttab/fstab mutation" "No storage unlock/mount/format/key/crypttab/fstab mutation"
require_doc_any "CT204 guardrail" "no CT204 start" "No CT204 start"
require_doc_any "PVESO guardrail" "no PVESO wake/start" "No PVESO wake/start"
require_doc_any "Cloudflare guardrail" "no Cloudflare/DNS/tunnel mutation" "No Cloudflare/DNS/tunnel mutation"

grep -Fq 'privateStorageInfrastructureGroup' "$APP_SRC"
grep -Fq 'Private backup storage policy:' "$APP_SRC"
grep -Fq 'ct-203' "$APP_SRC"
grep -Fq 'pvew' "$APP_SRC"
grep -Fq 'vm-200' "$APP_SRC"

if grep -nE "$LEGACY_RE" "$APP_SRC"; then
  echo "FAIL: legacy UI/source terms remain in active app source"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$APP_SRC"
fi

echo "PASS: 14J-LY UI legacy copy source patch guardrails present"
echo "PASS_${PHASE}"
