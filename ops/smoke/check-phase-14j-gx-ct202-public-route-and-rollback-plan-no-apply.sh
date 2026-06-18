#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gx-ct202-public-route-and-rollback-plan-no-apply"
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

require_line 'Phase 14J-GX documents the future public route and rollback plan required before any CT202 controller cutover.'
require_line 'This phase does **not** mutate Cloudflare, DNS, tunnels, public routes, CT202, systemd, laptop controller, or any database.'
require_line 'This phase does **not** approve CT202 public routing.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'VM 200 `website-edge` is the public/static website edge role only'
require_line 'website-edge must not host controller/queue/worker/model authority'
require_line 'website-edge must not expose Proxmox management'
require_line 'CT202 remains private and must not be exposed publicly until a later explicit route apply phase.'

require_line 'Required future route plan inputs'
require_line 'exact public hostname or hostname set'
require_line 'exact current public route target'
require_line 'exact proposed CT202 route target'
require_line 'exact rollback target'
require_line 'explicit approval phrase'

require_line 'Required future CT202 readiness before route apply'
require_line 'CT202 data authority path has been selected and approved'
require_line 'CT202 runtime secret/public API key delivery has been applied safely if required'
require_line 'CT202 service runtime has passed private rehearsal'
require_line 'laptop controller fallback is preserved'
require_line 'no split-brain controller writes are possible'

require_line 'Public route cutover strategy'
require_line 'Stage 1 - preflight only'
require_line 'Stage 2 - CT202 private readiness'
require_line 'Stage 3 - public route switch'
require_line 'Stage 4 - post-cutover validation'
require_line 'Stage 5 - rollback if needed'

require_line 'Rollback trigger conditions'
require_line 'public health check fails'
require_line 'route points to the wrong target'
require_line 'Proxmox management appears reachable from public traffic'
require_line 'model/Ollama/worker endpoint appears reachable from public traffic'

require_line 'Required future public safety checks'
require_line 'no public Proxmox management exposure'
require_line 'no public CT201 exposure'
require_line 'no public CT101 exposure unless separately approved'
require_line 'no public model/Ollama exposure'
require_line 'no public worker control exposure'
require_line 'no public DB exposure'

require_line 'Cloudflare boundary'
require_line 'A future Cloudflare or route mutation must not happen from this phase.'
require_line 'no broad/global Cloudflare API key should be used'

require_line 'Laptop fallback requirements'
require_line 'how CT202 and laptop avoid split-brain writes'
require_line 'how public traffic returns to laptop/controller path'

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
require_line 'no CT101 call'
require_line 'no model/Ollama endpoint call'
require_line 'no worker start'
require_line 'no production DB/job mutation'
require_line 'no rerun of the Phase 14J-AG apply wrapper'
require_line 'no destructive GitHub branch/repository deletion'

require_line 'Next safe phase: Phase 14J-GY - CT202 laptop fallback and split-brain prevention plan, no apply.'

require_absent 'APPROVE_ROUTE_APPLY'
require_absent 'APPROVE_CLOUDFLARE_APPLY'
require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'cloudflare tunnel route dns'
require_absent 'cloudflared tunnel route'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
