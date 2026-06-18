#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lq-workstation-ssh-alias-diagnostic-read-only"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "Phase 14J-LQ" "$DOC"
grep -Fq "Workstation SSH Alias Diagnostic, Read Only" "$DOC"
grep -Fq "ef01858" "$DOC"
grep -Fq "controller-phase-14j-lp-pvew-operator-access-inventory-diagnostic-plan-no-apply-2026-06-18" "$DOC"
grep -Fq "public_system_status_http=200" "$DOC"
grep -Fq "overall_state=online" "$DOC"
grep -Fq "node_ids_sorted=ct-203,ct-204,pvew,vm-200" "$DOC"
grep -Fq "ct204_expected_state=stopped" "$DOC"
grep -Fq "ct204_data_authority=false" "$DOC"
grep -Fq "ssh_config_host_pvew_block=missing" "$DOC"
grep -Fq "ssh_g_hostname_class=literal-pvew-no-hostname-override" "$DOC"
grep -Fq "tailscale_backend_state=Running" "$DOC"
grep -Fq "tailscale_pvew_peer_hint=present-redacted" "$DOC"
grep -Fq "diagnostic_result=pvew_ssh_alias_missing_or_unconfigured" "$DOC"
grep -Fq "No SSH alias was added by this phase" "$DOC"
grep -Fq "No SSH connection was attempted by this phase" "$DOC"
grep -Fq "No storage/DB/service/route/authority mutation occurred" "$DOC"
grep -Fq "PASS_PHASE_14J_LQ_WORKSTATION_SSH_ALIAS_DIAGNOSTIC_READ_ONLY_RECORDED" "$DOC"

echo "PASS: 14J-LQ workstation SSH alias diagnostic evidence doc guardrails present"
echo "PASS_${PHASE}"
