#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hb-data-authority-comparison-plan-no-import-no-apply"
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

require_present 'Phase 14J-HB - Data authority comparison plan, no import/no apply'
require_present 'Previous checkpoint: Phase 14J-HA at commit `ce886c5`'
require_present 'This phase is docs/smoke only.'
require_present 'laptop controller remains the live controller/queue authority'
require_present 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_present 'CT202 remains private and non-authoritative'
require_present 'CT202 service is disabled/inactive'
require_present 'CT202 onboot/autostart is off'
require_present 'CT202 has no checked controller/smoke listener active'
require_present 'laptop DB has live operational rows'
require_present 'CT202 DB is a fresh local candidate DB'
require_present 'The live laptop DB and CT202 candidate DB are not equivalent'
require_present 'Path 1 - Fresh-start CT202 authority'
require_present 'Path 2 - Selective import'
require_present 'Path 3 - Full migration'
require_present 'DB path existence'
require_present 'SQLite quick_check'
require_present 'application table count'
require_present 'table name lists'
require_present 'schema SQL hashes'
require_present 'selected safe row counts'
require_present 'It must avoid:'
require_present 'row content'
require_present 'user/session tokens'
require_present 'SQL dumps'
require_present 'table data dumps'
require_present 'full DB file copies'
require_present 'secrets in ChatGPT'
require_present 'secrets in `APC_LAST_OUTPUT`'
require_present 'APPROVE_PHASE_14J_HC_READ_ONLY_DATA_AUTHORITY_PREFLIGHT_NO_IMPORT_NO_APPLY'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not open the cutover gate.'

require_present 'CT202 authority cutover'
require_present 'CT202 data migration or import'
require_present 'SQLite file copy'
require_present 'SQL dump'
require_present 'table data dump'
require_present 'backup creation'
require_present 'restore operation'
require_present 'live laptop DB mutation'
require_present 'CT202 DB mutation'
require_present '`systemctl start`'
require_present '`systemctl enable`'
require_present 'CT202 onboot/autostart mutation'
require_present 'public route mutation'
require_present 'Cloudflare, DNS, or tunnel mutation'
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
