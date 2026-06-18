#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hh-read-only-code-path-table-usage-inspection-no-db-mutation-no-apply"
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

require_present 'Phase 14J-HH - Read-only code-path table usage inspection, no DB mutation/no apply'
require_present 'Previous checkpoint: Phase 14J-HG at commit `bd6fa14`'
require_present 'APPROVE_PHASE_14J_HH_READ_ONLY_CODE_PATH_TABLE_USAGE_INSPECTION_NO_DB_MUTATION_NO_APPLY'
require_present 'This phase was read-only.'
require_present 'DB files opened: `0`'
require_present 'row content output: `0`'
require_present 'The scan included `.cleanup-archive` paths.'
require_present 'scanned file count: `930`'
require_present 'scanned line count: `295959`'
require_present '`workers` appears in runtime scan output'
require_present 'laptop `workers` has `29` columns while CT202 `workers` has `21`'
require_present '`credit_reservations` appears in runtime code'
require_present 'laptop `credit_reservations` has `15` columns while CT202 has `17`'
require_present '`user_credit_ledger` appears in runtime code'
require_present 'CT202-only `credit_ledger` did not appear in app/runtime code scan'
require_present 'CT202-only `user_credit_wallets` did not appear in app/runtime code scan'
require_present 'Study tables appear in runtime code.'
require_present 'CT202 missing Study tables blocks CT202 authority for Study continuity.'
require_present '`calendar_events` appears in runtime scan output.'
require_present 'CT202 missing `calendar_events` blocks local calendar continuity'
require_present 'A separate runtime cutover policy is required.'
require_present 'Session state remains relevant.'
require_present 'CT202 should not become controller/data authority as-is.'
require_present 'No data authority path was selected by this phase.'
require_present 'Phase 14J-HI - no-apply reconciliation path recommendation'
require_present 'APPROVE_PHASE_14J_HI_NO_APPLY_RECONCILIATION_PATH_RECOMMENDATION'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
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
