#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-af-pveso-control-route-repair-plan-no-apply.md"

need() {
  local text="$1"
  if ! grep -Fq -- "$text" "$DOC"; then
    echo "missing_required_text=$text"
    exit 1
  fi
}

need 'Do not attempt another CT101 live start through the current CT203-to-PVESO route'
need 'No unrestricted PVESO control route was proven.'
need 'CT101 remained stopped after the failed start attempts.'
need 'A separate explicit approval boundary before any CT101 start.'
need 'E3Z-AG: read-only control-route repair readiness diagnostic.'

# Narrow safety check: reject actual shell command lines that would perform a live operation in this no-apply plan.
# This intentionally does not reject harmless planning words such as "model" or "apply".
if grep -En '^(sudo +)?(pct +start|pct +stop|qm +start|qm +stop|systemctl +(start|stop|restart|reload|enable|disable)|sqlite3 +.*(UPDATE|INSERT|DELETE)|curl +.*11434)' "$DOC"; then
  echo 'forbidden_live_command_line_present'
  exit 2
fi

echo 'E3Z_AF_SMOKE_OK=1'
