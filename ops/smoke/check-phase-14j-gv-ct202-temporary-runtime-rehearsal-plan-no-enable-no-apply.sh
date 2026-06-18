#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gv-ct202-temporary-runtime-rehearsal-plan-no-enable-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

require_line() {
  local pattern="$1"
  echo "CHECK: $pattern"
  grep -F "$pattern" "$DOC" >/dev/null
  echo "PASS: $pattern"
}

require_absent() {
  local pattern="$1"
  echo "CHECK_ABSENT: $pattern"
  if grep -F "$pattern" "$DOC" >/dev/null; then
    echo "FAIL: forbidden literal present: $pattern" >&2
    exit 1
  fi
  echo "PASS_ABSENT: $pattern"
}

require_line 'Phase 14J-GV documents a future CT202 temporary runtime rehearsal plan.'
require_line 'This phase does **not** start CT202 controller runtime.'
require_line 'This phase does **not** enable CT202 service.'
require_line 'This phase does **not** mutate CT202, systemd, Proxmox onboot/autostart, Cloudflare, public routes, laptop controller, or any database.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'A future rehearsal should prove that CT202 can temporarily start, answer private loopback runtime checks, then return to disabled/inactive with no persistent activation.'
require_line 'persistent service enablement'
require_line 'Proxmox onboot/autostart'
require_line 'public route mutation'
require_line 'data migration/import'
require_line 'laptop controller shutdown'
require_line 'CT202 authority promotion'

require_line 'Future rehearsal sequence'
require_line 'Start the service temporarily only for private loopback smoke.'
require_line 'Smoke only private loopback runtime endpoints.'
require_line 'Stop the service.'
require_line 'Verify service returns inactive.'
require_line 'Verify service remains disabled.'
require_line 'Verify CT202 onboot/autostart remains off.'
require_line 'Verify no guarded-port listener/runtime remains.'

require_line 'Future private smoke targets'
require_line '`/openapi.json`'
require_line 'No public hostname should be used in this rehearsal.'
require_line 'No public route should point to CT202.'
require_line 'No CT101, model, worker, or production job endpoint should be called.'

require_line 'Runtime secret boundary'
require_line 'This phase creates no secret.'
require_line 'This phase creates no environment file.'
require_line 'This phase mutates no systemd unit.'

require_line 'Stop and rollback requirements for future rehearsal'
require_line 'service inactive after rehearsal'
require_line 'service disabled after rehearsal'
require_line 'no controller listener on guarded ports'
require_line 'no Uvicorn controller process'
require_line 'CT202 onboot/autostart still off'
require_line 'laptop controller still live authority'
require_line 'laptop DB still live authority'

require_line 'no CT202 authority cutover'
require_line 'no CT202 temporary runtime start'
require_line 'no CT202 persistent runtime activation'
require_line 'no CT202 data migration/import'
require_line 'no laptop DB export/import'
require_line 'no SQLite copy'
require_line 'no secret generation'
require_line 'no secret printing'
require_line 'no secret file creation'
require_line 'no environment file creation'
require_line 'no systemd unit mutation'
require_line 'no `systemctl start`'
require_line 'no `systemctl enable`'
require_line 'no `systemctl daemon-reload`'
require_line 'no CT202 onboot/autostart mutation'
require_line 'no public route mutation'
require_line 'no Cloudflare mutation'
require_line 'no laptop controller stop'
require_line 'no live laptop DB mutation'
require_line 'no CT101 call'
require_line 'no model/Ollama endpoint call'
require_line 'no worker start'
require_line 'no production DB/job mutation'
require_line 'no rerun of the Phase 14J-AG apply wrapper'
require_line 'no destructive GitHub branch/repository deletion'

require_line 'Next safe phase: Phase 14J-GW - CT202 data authority preflight plan, no import, no apply.'

require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_SECRET_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
