#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gz-ct202-cutover-readiness-gate-and-remaining-blockers-summary-no-apply"
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

require_line 'Phase 14J-GZ summarizes CT202 cutover readiness, remaining blockers, and the explicit gate that must remain closed before any controller authority cutover.'
require_line 'This phase does **not** approve cutover.'
require_line 'This phase does **not** mutate CT202, systemd, Proxmox onboot/autostart, Cloudflare, DNS, tunnels, laptop controller, CT201, CT101, workers, models, or any database.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'Phase 14J-GS - CT202 controller cutover plan no apply'
require_line 'Phase 14J-GT - CT202 cutover design options no apply'
require_line 'Phase 14J-GU - CT202 persistent secret/public API key policy no apply'
require_line 'Phase 14J-GV - CT202 temporary runtime rehearsal plan no enable/no apply'
require_line 'Phase 14J-GW - CT202 data authority preflight plan no import/no apply'
require_line 'Phase 14J-GX - CT202 public route and rollback plan no apply'
require_line 'Phase 14J-GY - CT202 laptop fallback and split-brain prevention plan no apply'

require_line 'The CT202 controller cutover readiness gate remains **CLOSED**.'
require_line 'A future cutover apply cannot proceed from this phase.'

require_line 'Blocker 1 - Data authority path not selected for apply'
require_line 'Blocker 2 - Secret policy not applied'
require_line 'Blocker 3 - Runtime rehearsal not executed in this planning sequence'
require_line 'Blocker 4 - Public route not approved or applied'
require_line 'Blocker 5 - Laptop fallback must be proven current'
require_line 'Blocker 6 - Worker/model runtime remains out of scope'

require_line 'Gate conditions required before opening apply consideration'
require_line 'data authority path selected'
require_line 'secret/runtime auth policy applied or explicitly not needed'
require_line 'public route target and rollback target approved'
require_line 'laptop fallback and split-brain prevention approved'
require_line 'explicit approval phrase for the specific apply phase'

require_line 'Recommended next milestone: Source refresh through Phase 14J-GZ.'
require_line 'Next recommended milestone: Source refresh through Phase 14J-GZ before any future apply approval.'

require_line 'no CT202 authority cutover'
require_line 'no CT202 public route approval'
require_line 'no CT202 data migration/import'
require_line 'no laptop DB export/import'
require_line 'no SQLite copy'
require_line 'no SQL dump'
require_line 'no table data dump'
require_line 'no live DB mutation'
require_line 'no backup creation'
require_line 'no restore operation'
require_line 'no secret generation'
require_line 'no secret printing'
require_line 'no secret file creation'
require_line 'no environment file creation'
require_line 'no systemd unit mutation'
require_line 'no `systemctl start`'
require_line 'no `systemctl enable`'
require_line 'no `systemctl daemon-reload`'
require_line 'no CT202 onboot/autostart mutation'
require_line 'no persistent controller runtime activation'
require_line 'no public route mutation'
require_line 'no Cloudflare mutation'
require_line 'no DNS mutation'
require_line 'no tunnel mutation'
require_line 'no laptop controller stop'
require_line 'no laptop controller pause'
require_line 'no CT101 call'
require_line 'no model/Ollama endpoint call'
require_line 'no worker start'
require_line 'no production DB/job mutation'
require_line 'no rerun of the Phase 14J-AG apply wrapper'
require_line 'no destructive GitHub branch/repository deletion'

require_line 'CT202 cutover planning has reached a closed readiness gate.'
require_line 'CT202 remains private and non-authoritative.'
require_line 'Laptop controller and laptop-local `edge_queue.sqlite3` remain live authority.'

require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'APPROVE_ROUTE_APPLY'
require_absent 'APPROVE_CLOUDFLARE_APPLY'
require_absent 'APPROVE_SECRET_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'cloudflared tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
