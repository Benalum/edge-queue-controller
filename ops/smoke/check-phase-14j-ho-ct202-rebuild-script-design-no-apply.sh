#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ho-ct202-rebuild-script-design-no-apply"
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

require_present 'Phase 14J-HO - CT202 rebuild script design, no apply'
require_present 'Previous checkpoint: Phase 14J-HN at commit `500aec1`'
require_present 'APPROVE_PHASE_14J_HO_CT202_REBUILD_SCRIPT_DESIGN_NO_APPLY'
require_present 'This phase designs the future script structure'
require_present 'This phase does not create a rebuild script artifact.'
require_present 'This phase does not execute a rebuild.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase is docs/smoke only.'
require_present 'Phase 14J-HK target schema manifest exists.'
require_present 'Phase 14J-HM guarded CT202 backup artifacts exist.'
require_present 'Phase 14J-HN backup artifact verification passed.'
require_present 'CT202 cutover readiness gate remains CLOSED.'
require_present '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z'
require_present '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314'
require_present 'The future rebuild script should create or prepare a **CT202 candidate schema**'
require_present 'The future script must not promote CT202 to authority.'
require_present 'The recommended next artifact should be a **no-apply script artifact**'
require_present 'This phase intentionally does not define a rebuild-apply approval phrase.'
require_present 'APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY'
require_present 'Resolve `pveso` using the existing SSH/Tailscale fallback pattern'
require_present 'CT202 status is `running`'
require_present 'CT202 hostname is `edge-controller`'
require_present 'CT202 onboot is `0`'
require_present 'no checked listener is active on `7070`, `8787`, or `8765`'
require_present 'Verify the HM/HN backup directory exists.'
require_present 'Verify artifact size/hash values match the HN record.'
require_present '`no_sqlite_open=1`'
require_present '`no_sql_dump=1`'
require_present '`no_row_content=1`'
require_present '`no_service_start=1`'
require_present '`no_service_enable=1`'
require_present '`no_onboot_mutation=1`'
require_present '`no_rebuild=1`'
require_present '`no_cutover=1`'
require_present 'Verify the manifest includes the `39` laptop continuity tables.'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present 'Do not treat CT202 current DB as schema truth.'
require_present 'Do not treat CT202-only wallet tables as authoritative.'
require_present 'Target include groups'
require_present 'Target include table list'
require_present '`ad_reward_events`'
require_present '`calendar_events`'
require_present '`credit_reservations`'
require_present '`study_decks`'
require_present '`study_cards`'
require_present '`study_sessions`'
require_present '`user_credit_ledger`'
require_present '`worker_events`'
require_present '`workers`'
require_present 'Target omit/defer handling'
require_present 'Critical mismatch handling'
require_present 'The future script design must target the current runtime-compatible laptop `workers` schema.'
require_present 'It must include lane/default-off metadata columns.'
require_present 'CT202 has `21` columns and laptop has `29`'
require_present 'CT202 has `17` columns and laptop has `15`'
require_present 'Future script output requirements'
require_present 'ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh'
require_present 'The artifact should be executable but safe by default.'
require_present 'The artifact should fail closed unless the exact no-apply artifact approval phrase is set.'
require_present 'The artifact should not contain any apply approval phrase.'
require_present 'Future script sections'
require_present 'Deferred apply design'
require_present 'Phase 14J-HP - CT202 rebuild script artifact, no apply'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not authorize restore.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'Path C execution'
require_present 'CT202 rebuild execution'
require_present 'CT202 schema apply'
require_present 'CT202 data migration or import'
require_present 'SQLite open with `sqlite3`'
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
