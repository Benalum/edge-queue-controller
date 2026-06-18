#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hd-data-authority-decision-matrix-and-schema-reconciliation-options-no-apply"
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

require_present 'Phase 14J-HD - Data authority decision matrix and schema reconciliation options, no apply'
require_present 'Previous checkpoint: Phase 14J-HC at commit `205e90f`'
require_present 'This phase does not select a data authority path.'
require_present 'This phase is docs/smoke only.'
require_present 'CT202 cannot be promoted as-is under the assumption that it has equivalent data.'
require_present 'laptop application table count: `39`'
require_present 'CT202 application table count: `25`'
require_present 'tables only on laptop: `16`'
require_present 'tables only on CT202: `2`'
require_present 'table-list hash match: `no`'
require_present 'schema hash match: `no`'
require_present 'Option A - Fresh-start CT202 authority'
require_present 'Option B - Selective import'
require_present 'Option C - Full migration'
require_present 'Not recommended for production user continuity'
require_present 'Best candidate if the goal is to preserve user-facing state'
require_present 'Most complete for continuity, but highest operational risk'
require_present 'Schema reconciliation needs'
require_present 'Why does CT202 have `credit_ledger` and `user_credit_wallets`'
require_present 'Should sessions be preserved or invalidated at cutover?'
require_present 'The recommended next no-apply phase is a schema reconciliation plan'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'No data authority path is selected by this phase.'
require_present 'Future approvals still required'

require_present '`ad_reward_events`'
require_present '`calendar_events`'
require_present '`study_cards`'
require_present '`study_sessions`'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present '`jobs`'
require_present '`workers`'
require_present '`user_sessions`'
require_present '`user_credit_ledger`'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'CT202 data migration or import'
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
