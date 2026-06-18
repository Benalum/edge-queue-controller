#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lv-isolated-restore-drill-design-no-apply"
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

require "Phase 14J-LV"
require "Isolated Restore-Drill Design, No Apply"
require "f9b6ebb"
require "controller-phase-14j-lu-ct204-backup-data-role-no-apply-2026-06-18"
require "CT203 remains the live controller/API/queue authority"
require "CT204 remains stopped, backup-data-only, and non-authoritative"
require "manual-unlock-only"
require "restore execution"
require "isolated copy"
require "No live DB restore"
require "No controller DB swap"
require "No CT203 DB overwrite"
require "No CT204 start"
require "No CT204 data authority change"
require "No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation"
require "No service restart/reload/enable/start/stop"
require "No Cloudflare/DNS/tunnel mutation"
require "No PVESO wake/start"
require "No private user data output"
require "APPROVE_PHASE_14J_LW_ISOLATED_RESTORE_DRILL_READ_ONLY_COPY_ONLY"
require "PASS_PHASE_14J_LV_ISOLATED_RESTORE_DRILL_DESIGN_NO_APPLY_DONE"

echo "PASS: 14J-LV isolated restore-drill no-apply guardrails present"
echo "PASS_${PHASE}"
