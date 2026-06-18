#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hg-schema-reconciliation-decision-plan-no-apply"
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

require_present 'Phase 14J-HG - Schema reconciliation decision plan, no apply'
require_present 'Previous checkpoint: Phase 14J-HF at commit `9f70c5f`'
require_present 'This phase does not select a data authority path'
require_present 'This phase is docs/smoke only.'
require_present 'shared tables with matching safe schema-detail hash: `21`'
require_present 'shared tables with mismatched safe schema-detail hash: `2`'
require_present '`credit_reservations`: laptop columns=`15`, CT202 columns=`17`'
require_present '`workers`: laptop columns=`29`, CT202 columns=`21`'
require_present '`study_decks`'
require_present '`study_cards`'
require_present '`study_sessions`'
require_present '`calendar_events`'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present 'Treat laptop schema as current continuity baseline.'
require_present 'Decision 1 - Study tables'
require_present 'Decision 2 - Calendar table'
require_present 'Decision 3 - Credit schema'
require_present 'Decision 4 - `credit_reservations` mismatch'
require_present 'Decision 5 - `workers` mismatch'
require_present 'Decision 6 - Runtime queue state'
require_present 'Decision 7 - Power/platform tables'
require_present 'Path A - Fresh-start CT202'
require_present 'Path B - Forward-migrate CT202 schema'
require_present 'Path C - Rebuild CT202 from laptop schema'
require_present 'Path D - Full laptop DB migration'
require_present 'Phase 14J-HH - read-only code-path table usage inspection, no DB mutation/no apply'
require_present 'APPROVE_PHASE_14J_HH_READ_ONLY_CODE_PATH_TABLE_USAGE_INSPECTION_NO_DB_MUTATION_NO_APPLY'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'No data authority path is selected by this phase.'
require_present 'Do not run migration/import/copy/dump from this phase.'

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
