#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hm-ct202-guarded-backup-only-no-rebuild"
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

require_present 'Phase 14J-HM - CT202 guarded backup only, no rebuild'
require_present 'Previous checkpoint: Phase 14J-HL at commit `0a12db6`'
require_present 'APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD'
require_present 'This phase created CT202 candidate backup artifacts on `pveso` only.'
require_present 'The first HM attempt failed safely before remote work'
require_present 'HM-R2 used SSH/Tailscale fallback resolution.'
require_present 'CT status: `running`'
require_present 'CT hostname: `edge-controller`'
require_present 'CT onboot: `0`'
require_present 'service enabled state: `disabled`'
require_present 'service active state: `inactive`'
require_present 'source size: `262144`'
require_present 'source sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`'
require_present '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z'
require_present '`ct202-edge_queue.sqlite3`'
require_present '`ct202-pct-config.txt`'
require_present '`ct202-app-summary.txt`'
require_present '`ct202-service-summary.txt`'
require_present '`ct202-env-config-posture.txt`'
require_present '`rollback-checklist.txt`'
require_present '`manifest.txt`'
require_present '`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`'
require_present '`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`'
require_present 'DB backup size matched source size'
require_present 'DB backup SHA256 matched source SHA256'
require_present 'no SQLite DB was opened with `sqlite3`'
require_present 'no SQL dump was performed'
require_present 'no row content was printed'
require_present 'no service start/enable was performed'
require_present 'CT202 service remained `disabled/inactive`'
require_present 'CT202 remained private candidate only'
require_present 'no rebuild/apply/cutover was performed'
require_present 'HEAD: `0a12db6`'
require_present 'working tree: clean'
require_present 'The live backup command did not mutate the repo.'
require_present 'laptop controller remains live authority'
require_present 'laptop-local DB remains live authority'
require_present 'CT202 cutover readiness gate remains CLOSED'
require_present 'Phase 14J-HN - CT202 backup artifact verification record, no restore/no rebuild'
require_present 'APPROVE_PHASE_14J_HN_CT202_BACKUP_ARTIFACT_VERIFICATION_RECORD_NO_RESTORE_NO_REBUILD'
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
