#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-am-pveso-local-worker-control-design-no-apply.md"
[[ -f "$DOC" ]]
grep -Fq 'CT203 remains the controller/API/queue/scheduler/DB authority.' "$DOC"
grep -Fq 'PVESO validates the request locally.' "$DOC"
grep -Fq 'Do not attempt another CT101 live start through the current CT203-to-PVESO route' "$DOC"
grep -Fq 'No arbitrary SSH command execution from CT203.' "$DOC"
grep -Fq 'Stage 16 E3Z-AN should be a no-apply implementation plan for Option A' "$DOC"
if grep -Eq '^[[:space:]]*(pct start|pct stop|pct reboot|qm start|qm stop|systemctl (start|restart|reload|enable|disable)|iptables -A|nft add|sqlite3 .*UPDATE|curl .*api/(generate|chat|embed|tags|version))' "$DOC"; then
  echo "forbidden_live_command_line_present"
  exit 2
fi
echo "E3Z_AM_SMOKE_OK=1"
