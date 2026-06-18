#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hs-ct202-private-rehearsal-plan-no-restore-no-rebuild-no-apply"
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

for needle in \
  'Phase 14J-HS - CT202 private rehearsal plan, no restore/no rebuild/no apply' \
  'Previous checkpoint: Phase 14J-HR at commit `23d2152`' \
  'APPROVE_PHASE_14J_HS_CT202_PRIVATE_REHEARSAL_PLAN_NO_RESTORE_NO_REBUILD_NO_APPLY' \
  'This phase does not create a rehearsal script artifact.' \
  'This phase does not execute rehearsal commands.' \
  'Phase 14J-HR no-restore rollback command artifact.' \
  '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'Private rehearsal goal' \
  'Private rehearsal non-goals' \
  'Proposed rehearsal order' \
  'Run the HP no-apply rebuild artifact in no-apply mode only.' \
  'Run the HR no-restore rollback artifact in no-restore mode only.' \
  'Verify target include count remains `39`.' \
  '`credit_ledger`' \
  '`user_credit_wallets`' \
  '`workers`' \
  '`credit_reservations`' \
  'Expected rehearsal artifact behavior' \
  'Faster-safe workflow note' \
  'Phase 14J-HT - CT202 private rehearsal artifact, no restore/no rebuild/no apply' \
  'APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY' \
  'CT202 controller cutover readiness gate remains CLOSED' \
  'Do not run migration/import/copy/dump from this phase.'
do
  require_present "$needle"
done

for needle in \
  'APPROVE_CUTOVER_APPLY' \
  'APPROVE_DATA_MIGRATION' \
  'APPROVE_RUNTIME_APPLY' \
  'APPROVE_ROUTE_APPLY' \
  'APPROVE_CLOUDFLARE_APPLY' \
  'APPROVE_SECRET_APPLY' \
  'APPROVE_REBUILD_APPLY' \
  'APPROVE_SCHEMA_APPLY' \
  'APPROVE_RESTORE_APPLY' \
  'systemctl enable edge-queue-controller.service' \
  'pct set 202 -onboot 1' \
  'cloudflare tunnel route' \
  'cloudflared tunnel route' \
  'ollama serve' \
  'sqlite3 edge_queue.sqlite3 .dump'
do
  require_absent "$needle"
done

echo "PASS: ${PHASE}"
