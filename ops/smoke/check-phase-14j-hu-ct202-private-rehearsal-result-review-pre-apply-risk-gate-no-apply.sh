#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hu-ct202-private-rehearsal-result-review-pre-apply-risk-gate-no-apply"
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
  'Phase 14J-HU - CT202 private rehearsal result review and pre-apply risk gate, no apply' \
  'Previous checkpoint: Phase 14J-HT at commit `2f1ae29`' \
  'APPROVE_PHASE_14J_HU_CT202_PRIVATE_REHEARSAL_RESULT_REVIEW_PRE_APPLY_RISK_GATE_NO_APPLY' \
  'This phase is docs/smoke only.' \
  'This phase does not create an apply artifact.' \
  'Phase 14J-HT completed successfully at commit `2f1ae29`.' \
  'private rehearsal artifact smoke passed' \
  'remote read-only CT202 posture checks passed' \
  'HM/HN backup artifact checks passed' \
  'CT202 status: `running`' \
  'CT202 hostname: `edge-controller`' \
  'CT202 onboot: `0`' \
  '`edge-queue-controller.service`: `disabled`' \
  '`edge-queue-controller.service`: `inactive`' \
  'no checked listener on `7070`, `8787`, or `8765`' \
  '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z' \
  'CT202 DB backup size: `262144`' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'PASS_FOR_NEXT_NO_APPLY_PLANNING_ONLY' \
  'This does not approve restore.' \
  'This does not approve rebuild.' \
  'This does not approve schema apply.' \
  'This does not approve data migration or import.' \
  'Remaining blockers before any real apply' \
  'Current allowed next work' \
  'Phase 14J-HV - CT202 candidate rebuild apply design, no apply' \
  'APPROVE_PHASE_14J_HV_CT202_CANDIDATE_REBUILD_APPLY_DESIGN_NO_APPLY' \
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
