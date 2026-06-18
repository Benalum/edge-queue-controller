#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gy-ct202-laptop-fallback-and-split-brain-prevention-plan-no-apply"
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

require_line 'Phase 14J-GY documents the laptop fallback and split-brain prevention requirements before any future CT202 controller cutover.'
require_line 'This phase does **not** stop, pause, demote, migrate, or mutate the laptop controller.'
require_line 'This phase does **not** promote CT202 or approve CT202 authority.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'Split-brain definition'
require_line 'laptop controller and CT202 both accepting queue writes'
require_line 'laptop DB and CT202 DB both receiving live production writes'
require_line 'public routes sending some writes to laptop and some writes to CT202'
require_line 'workers registering against the wrong controller'

require_line 'Fallback principle'
require_line 'route rollback path'
require_line 'controller process availability or restart path'
require_line 'laptop DB preservation'
require_line 'no split-brain write window'

require_line 'Future authority modes'
require_line 'Mode A - laptop authoritative, CT202 private candidate'
require_line 'Mode B - CT202 rehearsal, laptop still authoritative'
require_line 'Mode C - CT202 candidate cutover window'
require_line 'Mode D - CT202 authoritative, laptop fallback preserved'

require_line 'Required future split-brain prevention controls'
require_line 'single write authority'
require_line 'route ownership'
require_line 'queue write gating'
require_line 'worker registration target'
require_line 'rollback decision timing'
require_line 'post-rollback write reconciliation policy'

require_line 'Future laptop fallback checks'
require_line 'laptop controller status is known'
require_line 'laptop DB quick_check is OK'
require_line 'laptop route rollback target is known'
require_line 'laptop controller restart method is known if needed'
require_line 'rollback can be performed without CT202 dependency'

require_line 'Future CT202 cutover checks'
require_line 'CT202 service runtime is healthy privately'
require_line 'CT202 selected data-authority path is approved'
require_line 'CT202 will not compete with laptop for writes'

require_line 'Future rollback behavior'
require_line 'Scenario 1 - rollback before CT202 accepts writes'
require_line 'Scenario 2 - rollback after CT202 accepts writes'
require_line 'A future apply phase should avoid entering Scenario 2 until data-authority and reconciliation policy are approved.'

require_line 'Future route behavior'
require_line 'public writes must target only one controller authority'
require_line 'rollback must not create mixed routing'
require_line 'CT202 must not receive public traffic before approval'

require_line 'Future worker behavior'
require_line 'workers must know exactly one controller target'
require_line 'workers must not register to both laptop and CT202'
require_line 'no worker should start during controller cutover planning'

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

require_line 'Next safe phase: Phase 14J-GZ - CT202 cutover readiness gate and remaining blockers summary, no apply.'

require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'APPROVE_ROUTE_APPLY'
require_absent 'APPROVE_CLOUDFLARE_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'cloudflared tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
