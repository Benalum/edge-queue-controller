#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lz-ui-deploy-readiness-review-no-deploy"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

require() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required pattern: $pattern"
    exit 1
  fi
}

test -f "$DOC"

require "Phase 14J-LZ"
require "UI Deploy Readiness Review, No Deploy"
require "9b1b167"
require "controller-phase-14j-ly-ui-legacy-copy-source-patch-no-deploy-2026-06-18"
require "repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "repo_app_legacy_hits=absent"
require "public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public_deployed_legacy_hits=present"
require "public_status_http=200"
require "overall_state=online"
require "normalized_schema_version=2"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "storage_mount_state=unknown"
require "ct204_expected_state=stopped"
require "ct204_data_authority=false"
require "APPROVE_PHASE_14J_MA_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "no frontend deploy"
require "no VM200 write"
require "no qemu guest-agent operation"
require "no service restart/reload/enable/start/stop"
require "no Cloudflare/DNS/tunnel mutation"
require "PASS_PHASE_14J_LZ_UI_DEPLOY_READINESS_REVIEW_NO_DEPLOY_DONE"

echo "PASS: 14J-LZ UI deploy readiness review guardrails present"
echo "PASS_${PHASE}"
