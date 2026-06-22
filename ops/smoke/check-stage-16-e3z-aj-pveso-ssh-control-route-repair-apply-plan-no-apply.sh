#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-aj-pveso-ssh-control-route-repair-apply-plan-no-apply.md"
[[ -f "$DOC" ]]
grep -Fq 'Stage 16 E3Z-AJ' "$DOC"
grep -Fq 'Do not attempt another CT101 live start through the current CT203-to-PVESO route.' "$DOC"
grep -Fq 'PVEW direct TCP/22 to PVESO times out.' "$DOC"
grep -Fq 'CT203 arbitrary SSH command execution is not proven' "$DOC"
grep -Fq 'PVESO_UNRESTRICTED_CONTROL_ROUTE_CANDIDATE is not none' "$DOC"
grep -Fq 'Any live route repair must require a new explicit approval phrase and must not start CT101 in the same step.' "$DOC"
if grep -Eq '^\s*(pct start|qm start|systemctl (start|restart|reload|enable|disable)|iptables |nft |ufw |pvesh |ssh-keygen |tee .*authorized_keys|sed -i .*sshd_config)' "$DOC"; then
  echo 'forbidden_live_command_line_present'
  exit 2
fi
echo 'E3Z_AJ_SMOKE_OK=1'
