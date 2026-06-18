#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lu-ct204-backup-data-role-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

require() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required pattern: $pattern"
    exit 1
  fi
}

require_any() {
  local label="$1"
  shift
  local pattern
  for pattern in "$@"; do
    if grep -Fq "$pattern" "$DOC"; then
      echo "PASS: ${label}"
      return 0
    fi
  done
  echo "FAIL: missing any accepted pattern for ${label}"
  exit 1
}

test -f "$DOC"

require "Phase 14J-LU"
require "CT204 Backup-Data Role Design, No Apply"
require "eab99eb"
require "controller-phase-14j-lr-workstation-pvew-ssh-alias-add-plan-no-apply-2026-06-18"
require "CT203 remains the live controller/API/queue authority"
require "CT204 remains stopped, backup-data-only, and non-authoritative"
require "manual-unlock-only"
require "Public private storage mount state remains"
require "CT204 start"
require "CT204 data authority promotion"
require "DB restore/import/migration"
require "storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation"
require "APPROVE_PHASE_14J_LV_START_CT204_READ_ONLY_INSPECTION_ONLY"
require "APPROVE_PHASE_14J_LX_CT204_ISOLATED_RESTORE_DRILL_ONLY"
require "PASS_PHASE_14J_LU_CT204_BACKUP_DATA_ROLE_NO_APPLY_DONE"

require_any "ssh connection guardrail" \
  "No SSH connection attempt" \
  "SSH connection attempt;"

require_any "ssh config guardrail" \
  "No SSH config mutation" \
  "SSH config mutation;"

require_any "tailscale guardrail" \
  "No Tailscale config/auth mutation" \
  "Tailscale config/auth mutation;"

require_any "pveso guardrail" \
  "No PVESO wake/start" \
  "PVESO wake/start"

require_any "cloudflare guardrail" \
  "No Cloudflare/DNS/tunnel mutation" \
  "Cloudflare/DNS/tunnel mutation"

echo "PASS: 14J-LU CT204 backup-data role no-apply guardrails present"
echo "PASS_${PHASE}"
