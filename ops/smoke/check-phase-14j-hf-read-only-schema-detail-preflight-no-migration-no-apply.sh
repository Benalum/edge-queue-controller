#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hf-read-only-schema-detail-preflight-no-migration-no-apply"
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

require_present 'Phase 14J-HF - Read-only schema-detail preflight, no migration/no apply'
require_present 'Previous checkpoint: Phase 14J-HE at commit `da185c2`'
require_present 'APPROVE_PHASE_14J_HF_READ_ONLY_SCHEMA_DETAIL_PREFLIGHT_NO_MIGRATION_NO_APPLY'
require_present 'HF-R2 completed successfully and did not create a CT202 temp script file.'
require_present 'This phase was read-only.'
require_present 'HEAD: `da185c2`'
require_present 'working tree: clean'
require_present 'overall schema-detail hash SHA256: `e2d8ac2fc582791e6e995cd2d8d84f4df47ee14d67fdac0a2d6b9eb62c21ef6d`'
require_present 'overall schema-detail hash SHA256: `e3163d66a597658b76a2b031a28c4abff220cca194191a7f0e873c58ce31a171`'
require_present 'tables on both: `23`'
require_present 'tables only on laptop: `16`'
require_present 'tables only on CT202: `2`'
require_present 'shared-table schema-detail hash match count: `21`'
require_present 'shared-table schema-detail hash mismatch count: `2`'
require_present 'overall schema-detail hash match: `no`'
require_present '`credit_reservations`: laptop columns=`15`, CT202 columns=`17`'
require_present '`workers`: laptop columns=`29`, CT202 columns=`21`'
require_present '`app_users`: laptop=present, CT202=present, detail hash match=`yes`'
require_present '`user_sessions`: laptop=present, CT202=present, detail hash match=`yes`'
require_present '`jobs`: laptop=present, CT202=present, detail hash match=`yes`'
require_present '`workers`: laptop=present, CT202=present, detail hash match=`no`'
require_present '`user_credit_ledger`: laptop=present, CT202=present, detail hash match=`yes`'
require_present '`credit_ledger`: laptop=missing, CT202=present'
require_present '`user_credit_wallets`: laptop=missing, CT202=present'
require_present '`study_decks`: laptop=present, CT202=missing'
require_present '`study_cards`: laptop=present, CT202=missing'
require_present '`study_sessions`: laptop=present, CT202=missing'
require_present '`calendar_events`: laptop=present, CT202=missing'
require_present '`web_presence`: laptop=present, CT202=present, detail hash match=`yes`'
require_present 'Most shared tables match at safe schema-detail level.'
require_present 'Two shared tables require reconciliation'
require_present 'CT202 is missing user-facing Study and Calendar tables'
require_present 'CT202 has wallet/ledger credit tables that are missing on the laptop.'
require_present 'No data authority path was selected by this phase.'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'CT202 data migration or import'
require_present 'schema migration'
require_present 'SQLite copy'
require_present 'SQL dump'
require_present 'full CREATE TABLE dump'
require_present 'table data dump'
require_present 'row content output'
require_present 'default value output'
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
