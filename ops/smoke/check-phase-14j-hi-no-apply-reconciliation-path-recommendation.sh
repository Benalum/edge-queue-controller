#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hi-no-apply-reconciliation-path-recommendation"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

require_present() {
  local needle="$1"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$DOC"
  echo "PASS: $needle"
}

require_absent() {
  local needle="$1"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$DOC"; then
    echo "FAIL: unexpected text present: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

require_present 'Phase 14J-HI - No-apply reconciliation path recommendation'
require_present 'Previous checkpoint: Phase 14J-HH at commit `8627f84`'
require_present 'APPROVE_PHASE_14J_HI_NO_APPLY_RECONCILIATION_PATH_RECOMMENDATION'
require_present 'This phase recommends a preferred future planning direction'
require_present 'it does not select a data authority path'
require_present 'This phase is docs/smoke only.'
require_present 'laptop application table count: `39`'
require_present 'CT202 application table count: `25`'
require_present 'shared tables with matching detail hash: `21`'
require_present 'shared tables with mismatched detail hash: `2`'
require_present '`credit_reservations`: laptop columns=`15`, CT202 columns=`17`'
require_present '`workers`: laptop columns=`29`, CT202 columns=`21`'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present '`user_credit_ledger` appears in runtime code'
require_present 'Study tables appear in runtime code'
require_present '`calendar_events` appears in runtime code'
require_present 'Path A - Fresh-start CT202'
require_present 'Path B - Forward-migrate CT202 schema'
require_present 'Path C - Rebuild CT202 candidate from laptop continuity schema, then layer intentional deltas'
require_present 'Path D - Full laptop DB migration'
require_present 'Path C is the preferred future planning direction'
require_present 'This is only a recommendation.'
require_present 'not a data authority path selection'
require_present 'not an apply approval'
require_present 'Rebuilding the candidate schema is cleaner than layering unknown drift onto a private candidate DB.'
require_present 'Phase 14J-HJ - CT202 candidate rebuild plan, no apply'
require_present 'APPROVE_PHASE_14J_HJ_CT202_CANDIDATE_REBUILD_PLAN_NO_APPLY'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not authorize Path C execution.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'CT202 data migration or import'
require_present 'schema migration'
require_present 'SQLite open'
require_present 'SQLite copy'
require_present 'SQL dump'
require_present 'table data dump'
require_present 'row content output'
require_present 'live laptop DB mutation'
require_present 'CT202 DB mutation'
require_present 'backup creation'
require_present 'restore operation'
require_present '`systemctl start`'
require_present '`systemctl enable`'
require_present 'CT202 onboot/autostart mutation'
require_present 'Cloudflare, DNS, or tunnel mutation'
require_present 'public route mutation'
require_present 'laptop controller stop or pause'
require_present 'CT101 call'
require_present 'model/Ollama endpoint call'
require_present 'worker start'
require_present 'production DB/job mutation'
require_present 'secret generation, printing, or installation'
require_present 'destructive GitHub branch or repository deletion'

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
