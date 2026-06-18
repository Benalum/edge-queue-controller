#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hc-read-only-data-authority-preflight-no-import-no-apply"
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

require_present 'Phase 14J-HC - Read-only data-authority preflight, no import/no apply'
require_present 'Previous checkpoint: Phase 14J-HB at commit `aeff83c`'
require_present 'APPROVE_PHASE_14J_HC_READ_ONLY_DATA_AUTHORITY_PREFLIGHT_NO_IMPORT_NO_APPLY'
require_present 'This phase was read-only.'
require_present 'HEAD: `aeff83c`'
require_present 'working tree: clean'
require_present 'SQLite quick_check: `ok`'
require_present 'application table count: `39`'
require_present 'application table count: `25`'
require_present 'schema hash SHA256: `43acb940270daee930879fa8d09c8491154a2dfa4f83ddbf3087dabbd61dafec`'
require_present 'schema hash SHA256: `482fac6158f73033f56fe354b31719f80ee64dfdc3595d83a9a41868ff1da203`'
require_present 'table-list hash SHA256: `2c06687b7a7011a315c2287f35a7ae17478e7b1f75e71c425d224ec2b0d8d345`'
require_present 'table-list hash SHA256: `8782b953781558a81cfc0ac0473a5cfa1862763bb8e2f731258daf0c93cac817`'
require_present 'CT202 remained private and non-authoritative throughout the preflight.'
require_present 'service enabled state: `disabled`'
require_present 'service active state: `inactive`'
require_present 'no checked controller/smoke listener active'
require_present 'tables on both: `23`'
require_present 'tables only on laptop: `16`'
require_present 'tables only on CT202: `2`'
require_present 'table-list hash match: `no`'
require_present 'schema hash match: `no`'
require_present 'comparison conclusion: `schemas_differ_or_table_sets_differ_by_safe_hashes`'
require_present '`ad_reward_events`'
require_present '`calendar_events`'
require_present '`study_cards`'
require_present '`study_sessions`'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present '`jobs`: laptop=`22`, CT202=`0`'
require_present '`user_sessions`: laptop=`233`, CT202=`0`'
require_present '`workers`: laptop=`2`, CT202=`0`'
require_present 'The live laptop DB and CT202 candidate DB are not equivalent.'
require_present 'CT202 must not be promoted as-is under the assumption that it has equivalent data'
require_present 'no data authority path was selected by this phase'
require_present 'no data migration/import/copy/dump was performed'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'Fresh-start CT202 authority'
require_present 'Selective import'
require_present 'Full migration'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'CT202 data migration or import'
require_present 'SQLite copy'
require_present 'SQL dump'
require_present 'table data dump'
require_present 'row content output'
require_present 'live laptop DB mutation'
require_present 'CT202 DB mutation'
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
