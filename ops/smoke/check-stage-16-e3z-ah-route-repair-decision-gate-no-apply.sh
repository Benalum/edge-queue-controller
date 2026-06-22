#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-ah-route-repair-decision-gate-no-apply.md"
[[ -f "${DOC}" ]] || { echo "missing_doc"; exit 1; }

grep -Fq 'Do not attempt another CT101 live start through the current CT203-to-PVESO route.' "${DOC}" || { echo "missing_current_route_blocker"; exit 2; }
grep -Fq 'Option 1 — Preferred: repair PVEW direct LAN SSH to PVESO' "${DOC}" || { echo "missing_pvew_repair_option"; exit 3; }
grep -Fq 'Option 2 — Manual PVESO console start path' "${DOC}" || { echo "missing_manual_console_option"; exit 4; }
grep -Fq 'Option 3 — CT203 forced-command repair' "${DOC}" || { echo "missing_ct203_forced_command_option"; exit 5; }
grep -Fq 'No CT101 start in this phase.' "${DOC}" || { echo "missing_no_ct101_start"; exit 6; }
grep -Fq 'No DB writes' "${DOC}" || { echo "missing_no_db_write"; exit 7; }
grep -Fq 'No model endpoint calls' "${DOC}" || { echo "missing_no_model_calls"; exit 8; }
grep -Fq 'The next live mutation must be separately approved.' "${DOC}" || { echo "missing_approval_boundary"; exit 9; }

# Reject actual command-looking live operations in this repo-only artifact.
if grep -nE '^\s*(pct start|pct stop|pct reboot|systemctl (start|stop|restart|reload|enable|disable|daemon-reload)|sqlite3 .*(INSERT|UPDATE|DELETE)|curl .*/api/(generate|chat|embed|version|tags))\b' "${DOC}"; then
  echo "forbidden_live_command_line_present"
  exit 10
fi

echo "E3Z_AH_SMOKE_OK=1"
