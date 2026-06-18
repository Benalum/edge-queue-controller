#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hq-ct202-rollback-command-design-no-restore-no-rebuild"
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

require_present 'Phase 14J-HQ - CT202 rollback command design, no restore/no rebuild'
require_present 'Previous checkpoint: Phase 14J-HP at commit `7084fba`'
require_present 'APPROVE_PHASE_14J_HQ_CT202_ROLLBACK_COMMAND_DESIGN_NO_RESTORE_NO_REBUILD'
require_present 'This phase designs rollback command structure'
require_present 'This phase does not create a rollback command artifact.'
require_present 'This phase does not execute restore.'
require_present 'This phase does not execute rebuild.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase is docs/smoke only.'
require_present 'Phase 14J-HM guarded CT202 backup artifacts exist.'
require_present 'Phase 14J-HN backup artifact verification passed.'
require_present 'Phase 14J-HP no-apply rebuild script artifact exists.'
require_present 'CT202 cutover readiness gate remains CLOSED.'
require_present '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z'
require_present '`ct202-edge_queue.sqlite3`'
require_present '`rollback-checklist.txt`'
require_present '`manifest.txt`'
require_present '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314'
require_present '262144'
require_present 'The rollback command is for CT202 candidate state only.'
require_present 'The rollback command must not promote CT202 to authority.'
require_present 'The rollback command must not mutate laptop live authority.'
require_present 'The rollback command must not mutate public routes.'
require_present 'The recommended next artifact should be a **no-restore rollback command artifact**'
require_present 'This phase intentionally does not define a restore-apply approval phrase.'
require_present 'APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD'
require_present 'Resolve `pveso` using the SSH/Tailscale fallback pattern proven in HM/HN.'
require_present 'CT202 status is `running`'
require_present 'CT202 hostname is `edge-controller`'
require_present 'CT202 onboot is `0`'
require_present 'no checked listener is active on `7070`, `8787`, or `8765`'
require_present 'Verify the HM/HN backup directory exists.'
require_present 'DB backup size `262144`'
require_present 'DB backup SHA256 `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`'
require_present 'manifest SHA256 `dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`'
require_present 'rollback checklist SHA256 `3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`'
require_present '`no_sqlite_open=1`'
require_present '`no_sql_dump=1`'
require_present '`no_row_content=1`'
require_present '`no_service_start=1`'
require_present '`no_service_enable=1`'
require_present '`no_onboot_mutation=1`'
require_present '`no_rebuild=1`'
require_present '`no_cutover=1`'
require_present 'rollback checklist guard text'
require_present 'Future rollback order design'
require_present 'Confirm explicit future restore approval phrase.'
require_present 'Preserve current CT202 candidate DB as a pre-restore failure artifact if safe.'
require_present 'Keep CT202 service disabled/inactive.'
require_present 'Keep CT202 cutover readiness gate CLOSED.'
require_present 'Again, this phase does not execute any of the above.'
require_present 'Future failure artifact handling'
require_present 'Future output requirements'
require_present 'ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh'
require_present 'The artifact should be executable but safe by default.'
require_present 'The artifact should fail closed unless the exact no-restore artifact approval phrase is set.'
require_present 'The artifact should not contain any restore/apply approval phrase.'
require_present 'Deferred restore design'
require_present 'This HQ phase does not define the restore approval phrase.'
require_present 'Phase 14J-HP created a no-apply rebuild script artifact.'
require_present 'Phase 14J-HR - CT202 rollback command artifact, no restore/no rebuild'
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
