#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gw-ct202-data-authority-preflight-plan-no-import-no-apply"
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

require_line 'Phase 14J-GW documents the future read-only preflight required before any CT202 data authority decision.'
require_line 'This phase does **not** export, copy, import, migrate, mutate, or reconcile any database.'
require_line 'This phase does **not** select fresh-start, selective import, or full migration for apply.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'CT202 DB path: `/srv/edge-controller/data/edge_queue.sqlite3`'
require_line 'SQLite quick_check returned `ok`'
require_line 'application table count was `25`'
require_line '`jobs` row count was `0`'
require_line '`workers` row count was `0`'
require_line '`user_sessions` row count was `0`'
require_line '`router_logs` row count was `0`'

require_line 'fresh-start CT202 authority'
require_line 'selective import from laptop DB to CT202 DB'
require_line 'full migration from laptop DB to CT202 DB'
require_line 'Phase 14J-GW does not choose or approve an apply path.'

require_line 'Future read-only preflight goals'
require_line 'table list comparison'
require_line 'per-table row counts'
require_line 'identification of volatile runtime tables'
require_line 'identification of durable user/account/credit/configuration tables'
require_line 'candidate import/exclude/defer table classification'

require_line 'Future table classification policy'
require_line 'Group A - likely durable/import candidates'
require_line 'Group B - likely volatile/exclude candidates'
require_line 'Group C - decide-later candidates'

require_line 'Future backup and rollback policy'
require_line 'split-brain prevention must be documented'
require_line 'laptop controller must not be stopped without explicit approval'

require_line 'Future validation policy'
require_line 'Avoid recording:'
require_line 'user personal data'
require_line 'secret values'
require_line 'full SQL dumps in ChatGPT or Source files'

require_line 'Fresh-start decision requirements'
require_line 'Selective-import decision requirements'
require_line 'Full-migration decision requirements'

require_line 'Next safe phase: Phase 14J-GX - CT202 public route and rollback plan, no apply.'

require_line 'no CT202 authority cutover'
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
require_line 'no laptop controller stop'
require_line 'no CT101 call'
require_line 'no model/Ollama endpoint call'
require_line 'no worker start'
require_line 'no production DB/job mutation'
require_line 'no rerun of the Phase 14J-AG apply wrapper'
require_line 'no destructive GitHub branch/repository deletion'

require_line 'No database was exported, copied, imported, migrated, dumped, mutated, backed up, restored, or reconciled by this phase.'

require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'
require_absent '.dump'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'ollama serve'

echo "PASS: ${PHASE}"
