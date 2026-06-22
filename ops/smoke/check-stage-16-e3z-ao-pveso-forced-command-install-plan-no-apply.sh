#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-ao-pveso-forced-command-install-plan-no-apply.md"

require_text() {
  local needle="$1"
  if ! grep -Fq -- "$needle" "$DOC"; then
    echo "missing_required_text=$needle"
    exit 2
  fi
}

[[ -f "$DOC" ]] || { echo "missing_doc=$DOC"; exit 1; }

require_text 'CT203 remains the controller/API/queue/scheduler/DB authority'
require_text 'CT101 llms is the intended model-worker container'
require_text 'ct101-start-if-stopped-and-hostname-llms'
require_text 'Do not call /api/generate'
require_text 'no live infra mutation occurred'
require_text 'Any CT101 start remains a separate approval boundary'

# Reject actual executable-looking live mutation lines in the plan body. This is intentionally narrow:
# it allows planning prose, but rejects command examples that would start CT101 or call models.
if grep -En '^[[:space:]]*(pct[[:space:]]+start[[:space:]]+101|curl[[:space:]].*/api/generate|systemctl[[:space:]]+(start|restart|enable)|iptables[[:space:]]|nft[[:space:]])' "$DOC"; then
  echo "forbidden_executable_live_command_line_present"
  exit 3
fi

echo "E3Z_AO_SMOKE_OK=1"
