#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lx-ui-legacy-copy-cleanup-plan-no-deploy"
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

require "Phase 14J-LX"
require "UI Legacy Copy Cleanup Plan, No Deploy"
require "2fd36f0"
require "controller-phase-14j-lw-status-ui-polish-read-only-review-2026-06-18"
require "legacy_ui_copy_hits=present"
require "CT101 /api/* compatibility endpoints"
require "ct101-laptop-queue-worker"
require "master-laptop"
require "pveso"
require "ct-101"
require "CT101 for logged-in users"
require "ct-203"
require "pvew"
require "vm-200"
require "ct-204"
require "no frontend deploy"
require "no VM200 write"
require "no qemu guest-agent operation"
require "no service restart/reload/enable/start/stop"
require "no CT204 start"
require "no PVESO wake/start"
require "no Cloudflare/DNS/tunnel mutation"
require "PASS_PHASE_14J_LX_UI_LEGACY_COPY_CLEANUP_PLAN_NO_DEPLOY_DONE"

echo "PASS: 14J-LX UI legacy copy cleanup plan guardrails present"
echo "PASS_${PHASE}"
