#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lr-workstation-pvew-ssh-alias-add-plan-no-apply"
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

require "Phase 14J-LR"
require "Workstation PVEW SSH Alias Add Plan, No Apply"
require "0106a29"
require "controller-phase-14j-lq-workstation-ssh-alias-diagnostic-read-only-2026-06-18"
require "ssh_config_host_pvew_block=missing"
require "ssh_g_hostname_class=literal-pvew-no-hostname-override"
require "tailscale_pvew_peer_hint=present-redacted"
require "diagnostic_result=pvew_ssh_alias_missing_or_unconfigured"
require "APPROVE_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY"
require "Host pvew"
require "HostName <PVEW_TAILSCALE_DNS_OR_SAFE_HOST_LABEL>"
require "ssh -G pvew"
require "PASS_PHASE_14J_LR_WORKSTATION_PVEW_SSH_ALIAS_ADD_PLAN_NO_APPLY_DONE"

require_any "ssh connection guardrail" \
  "No SSH connection attempt" \
  "SSH connection attempt;" \
  "does not edit \`~/.ssh/config\`, connect to PVEW"

require_any "ssh config guardrail" \
  "No SSH config mutation" \
  "SSH config mutation;" \
  "does not edit \`~/.ssh/config\`"

require_any "tailscale guardrail" \
  "No Tailscale config/auth mutation" \
  "Tailscale config/auth mutation;" \
  "change Tailscale"

require_any "db restore guardrail" \
  "No DB backup/create/restore/import/migration" \
  "DB restore/import/migration" \
  "restore DBs"

require_any "storage guardrail" \
  "No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation" \
  "storage unlock/mount/format/key/crypttab/fstab mutation" \
  "unlock storage"

require_any "ct204 guardrail" \
  "No CT204 start or data authority change" \
  "CT204 start or data authority change" \
  "start CT204"

echo "PASS: 14J-LR workstation PVEW SSH alias add plan guardrails present"
echo "PASS_${PHASE}"
