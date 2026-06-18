#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hl-ct202-rebuild-backup-rollback-plan-no-apply"
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

require_present 'Phase 14J-HL - CT202 rebuild backup and rollback plan, no apply'
require_present 'Previous checkpoint: Phase 14J-HK at commit `f23688e`'
require_present 'APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY'
require_present 'This phase designs backup, verification, rollback, and guard requirements only.'
require_present 'This phase does not create backups.'
require_present 'This phase does not execute a rebuild.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase is docs/smoke only.'
require_present 'CT202 cutover readiness gate remains CLOSED'
require_present 'Backup plan objective'
require_present 'CT202 candidate database'
require_present '/srv/edge-controller/data/edge_queue.sqlite3'
require_present 'do not run `.dump`'
require_present 'CT202 application tree summary'
require_present '/srv/edge-controller/app/current'
require_present 'CT202 service/unit posture'
require_present 'CT202 environment/config posture'
require_present 'CT202 container config posture'
require_present 'Host-side backup directory'
require_present 'This HL phase does not create that directory.'
require_present 'Artifacts not to include'
require_present 'Backup verification plan'
require_present 'Rollback plan objective'
require_present 'Rollback prerequisites'
require_present 'Rollback order for future design'
require_present 'This phase does not execute any rollback.'
require_present 'Guardrails for future backup-only phase'
require_present 'Backup-only phase output requirements'
require_present 'APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD'
require_present 'create CT202 candidate backup artifacts only'
require_present 'no CT202 rebuild'
require_present 'no schema apply'
require_present 'no data import'
require_present 'no route mutation'
require_present 'no service start/enable'
require_present 'no cutover'
require_present 'This phase intentionally does not define the rebuild-apply approval phrase.'
require_present 'This phase does not authorize backup creation.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'Path C execution'
require_present 'CT202 rebuild execution'
require_present 'guarded backup execution'
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
require_absent 'APPROVE_RESTORE_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'cloudflared tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
