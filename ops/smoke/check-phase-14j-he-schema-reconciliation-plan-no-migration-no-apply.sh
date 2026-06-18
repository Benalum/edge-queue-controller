#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-he-schema-reconciliation-plan-no-migration-no-apply"
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

require_present 'Phase 14J-HE - Schema reconciliation plan, no migration/no apply'
require_present 'Previous checkpoint: Phase 14J-HD at commit `eed02de`'
require_present 'This phase does not select a data authority path.'
require_present 'This phase is docs/smoke only.'
require_present 'It does not apply a schema migration.'
require_present 'laptop application table count: `39`'
require_present 'CT202 application table count: `25`'
require_present 'tables only on laptop: `16`'
require_present 'tables only on CT202: `2`'
require_present 'schema hash match: `no`'
require_present 'Required user-facing state'
require_present 'Required platform/accounting state'
require_present 'Router/reference state'
require_present 'Runtime/queue state'
require_present 'Power/platform operational state'
require_present 'GPU/session history'
require_present 'No laptop-only table should be silently dropped without an explicit note.'
require_present 'credit schema naming drift is the highest-priority reconciliation question'
require_present 'Shared-table schema handling plan'
require_present 'Credit schema reconciliation'
require_present 'Study and calendar reconciliation'
require_present 'Runtime queue reconciliation'
require_present 'Power/platform reconciliation'
require_present 'Recommended reconciliation sequence'
require_present 'Future read-only schema-detail preflight'
require_present 'APPROVE_PHASE_14J_HF_READ_ONLY_SCHEMA_DETAIL_PREFLIGHT_NO_MIGRATION_NO_APPLY'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'No data authority path is selected by this phase.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present '`ad_reward_events`'
require_present '`calendar_events`'
require_present '`study_cards`'
require_present '`study_sessions`'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present '`user_credit_ledger`'
require_present '`jobs`: `22`'
require_present '`workers`: `2`'
require_present '`user_sessions`: `233`'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'CT202 data migration or import'
require_present 'schema migration'
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
