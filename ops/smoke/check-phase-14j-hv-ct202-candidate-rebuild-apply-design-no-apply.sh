#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hv-ct202-candidate-rebuild-apply-design-no-apply"
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
  'Phase 14J-HV - CT202 candidate rebuild apply design, no apply' \
  'Previous checkpoint: Phase 14J-HU at commit `a47821d`' \
  'APPROVE_PHASE_14J_HV_CT202_CANDIDATE_REBUILD_APPLY_DESIGN_NO_APPLY' \
  'This phase is docs/smoke only.' \
  'This phase does not create an apply script.' \
  'PASS_FOR_NEXT_NO_APPLY_PLANNING_ONLY' \
  'CT202-private only' \
  'candidate-only' \
  'schema-first' \
  'The future candidate rebuild must not make CT202 public authority.' \
  'The future candidate rebuild must keep CT202 service disabled/inactive.' \
  'The future candidate rebuild must keep CT202 onboot `0`.' \
  '/srv/edge-controller/data/edge_queue.sqlite3' \
  'Required pre-apply guards for any future candidate rebuild' \
  'CT202 cutover readiness gate CLOSED' \
  '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'Required preservation behavior' \
  'The future apply phase must fail closed if candidate preservation fails.' \
  'Target include count:' \
  '`39` laptop continuity tables' \
  '`credit_ledger`' \
  '`user_credit_wallets`' \
  '`workers`' \
  '`credit_reservations`' \
  'No live laptop data import is authorized by this design.' \
  'No data authority path is selected by this design.' \
  'Future candidate rebuild output requirements' \
  'Future failure handling' \
  'Phase 14J-HW - CT202 candidate rebuild apply artifact, no apply' \
  'APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY' \
  'This phase intentionally does not define the real candidate rebuild approval phrase.' \
  'The CT202 controller cutover readiness gate remains CLOSED.' \
  'The CT202 candidate mutation gate remains CLOSED.' \
  'The CT202 restore gate remains CLOSED.' \
  'The CT202 schema apply gate remains CLOSED.' \
  'The data authority selection gate remains CLOSED.' \
  'Laptop controller and laptop-local DB remain live authority.' \
  'CT202 remains private candidate only.' \
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
