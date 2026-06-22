#!/usr/bin/env bash
set -Eeuo pipefail

DOC="docs/stage-16-e3z-an-pveso-forced-command-worker-control-plan-no-apply.md"
[[ -f "$DOC" ]] || { echo "missing_doc"; exit 1; }

required_texts=(
  'PVESO forced-command worker-control plan'
  'CT203 is the controller'
  'CT101 `llms`: model-worker container only; not the controller'
  'CT203 must not receive a general-purpose PVESO root shell through this path'
  'ct101-start-if-stopped-and-hostname-llms'
  'do not start Ollama manually'
  'do not call model endpoints'
  'Do not attempt another CT101 live start through the current CT203-to-PVESO route until the forced-command worker-control path is installed and validated.'
)

for text in "${required_texts[@]}"; do
  if ! grep -Fq "$text" "$DOC"; then
    echo "missing_required_text=$text"
    exit 2
  fi
done

# Narrow no-apply guard: reject only executable command-looking live operations in fenced/shell-like lines.
if grep -En '^[[:space:]]*(pct[[:space:]]+start|pct[[:space:]]+stop|qm[[:space:]]+start|qm[[:space:]]+stop|systemctl[[:space:]]+(start|stop|restart|reload|enable|disable|daemon-reload)|sqlite3[[:space:]].*(UPDATE|INSERT|DELETE)|curl[[:space:]].*/api/(generate|chat|embed|tags|version))' "$DOC"; then
  echo "forbidden_executable_live_operation_line_present"
  exit 3
fi

echo "E3Z_AN_SMOKE_OK=1"
