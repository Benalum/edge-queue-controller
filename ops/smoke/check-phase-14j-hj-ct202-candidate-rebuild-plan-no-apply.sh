#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hj-ct202-candidate-rebuild-plan-no-apply"
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

require_present 'Phase 14J-HJ - CT202 candidate rebuild plan, no apply'
require_present 'Previous checkpoint: Phase 14J-HI at commit `c4e0b2a`'
require_present 'APPROVE_PHASE_14J_HJ_CT202_CANDIDATE_REBUILD_PLAN_NO_APPLY'
require_present 'Path C - Rebuild CT202 candidate from laptop continuity schema, then layer intentional deltas.'
require_present 'This phase does not execute Path C.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not authorize a schema apply'
require_present 'This phase is docs/smoke only.'
require_present 'laptop app table count is `39`'
require_present 'CT202 app table count is `25`'
require_present 'shared mismatches remain for `workers` and `credit_reservations`'
require_present 'CT202 is missing active Study tables'
require_present 'CT202 is missing `calendar_events`'
require_present 'CT202-only `credit_ledger` and `user_credit_wallets` did not appear in app/runtime code scan'
require_present 'current repository runtime bootstrap code'
require_present 'Do not treat CT202 current DB as schema truth.'
require_present 'Do not treat CT202-only wallet tables as authoritative'
require_present 'Account and auth continuity group'
require_present 'Credit and accounting continuity group'
require_present 'Study continuity group'
require_present 'Calendar continuity group'
require_present 'Queue/runtime schema group'
require_present 'Router/reference group'
require_present 'Support/admin group'
require_present 'Optional GPU/session history group'
require_present 'Rows in these tables should not be blindly imported'
require_present 'Power/platform rows'
require_present 'CT202-only wallet drift'
require_present 'target schema manifest'
require_present 'runtime row policy'
require_present 'backup plan'
require_present 'rollback plan'
require_present 'rehearsal plan'
require_present 'cutover gate checklist'
require_present 'Keep CT202 service disabled/inactive until a separate runtime rehearsal gate.'
require_present 'Keep public routes unchanged until a separate cutover gate.'
require_present 'APPROVE_PHASE_14J_HK_CT202_TARGET_SCHEMA_MANIFEST_NO_APPLY'
require_present 'APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY'
require_present 'APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD'
require_present 'This phase does not define the rebuild-apply approval phrase to avoid accidental execution.'
require_present 'Phase 14J-HK - CT202 target schema manifest, no apply'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not authorize Path C execution.'
require_present 'This phase does not authorize a CT202 rebuild.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'Path C execution'
require_present 'CT202 rebuild execution'
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
require_absent 'APPROVE_REBUILD_APPLY'
require_absent 'APPROVE_SCHEMA_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'cloudflared tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
