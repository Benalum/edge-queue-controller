#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-at-ct101-ollama-service-unmask-start-plan-no-apply.md"

require_text() {
  local needle="$1"
  if ! grep -Fq -- "$needle" "$DOC"; then
    echo "missing_required_text=$needle"
    exit 2
  fi
}

require_absent() {
  local needle="$1"
  if grep -Fq -- "$needle" "$DOC"; then
    echo "forbidden_text_present=$needle"
    exit 3
  fi
}

require_text 'Ollama on CT101 is Docker-based'
require_text 'Do not call /api/generate'
require_text 'Do not call /api/chat'
require_text 'Do not run `ollama list`.'
require_text 'Do not start, stop, restart, create, recreate, or remove any Docker container.'
require_text 'Do not unmask or start `ollama.service` in this plan phase.'
require_text 'The next phase should be a read-only Docker inventory on CT101.'
require_text 'E3Z-AU must remain read-only.'
require_text 'CT203 DB/job/scheduler/timer guards before and after.'
require_text 'model endpoint calls remain forbidden'

# Avoid accidentally documenting an immediate apply as approved in this no-apply phase.
require_absent 'APPROVE_STAGE_16_E3Z_AU'
require_absent 'APPROVE_STAGE_16_E3Z_AV'

echo "E3Z_AT_R3_SMOKE_OK=1"
