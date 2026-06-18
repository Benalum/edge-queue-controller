#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hw-ct202-candidate-rebuild-apply-artifact-no-apply"
DOC="docs/${PHASE}.md"
SCRIPT="ops/rebuild/${PHASE}.sh"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"
test -f "$SCRIPT"
test -x "$SCRIPT"

require_present() {
  local file="$1"
  local needle="$2"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$file"
  echo "PASS: $needle"
}

require_absent() {
  local file="$1"
  local needle="$2"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: unexpected text present in $file: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

for needle in \
  'Phase 14J-HW - CT202 candidate rebuild apply artifact, no apply' \
  'Previous checkpoint: Phase 14J-HV at commit `87e446f`' \
  'APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY' \
  'This phase does not define the real candidate rebuild approval phrase.' \
  'ops/rebuild/phase-14j-hw-ct202-candidate-rebuild-apply-artifact-no-apply.sh' \
  'The artifact does not open SQLite with `sqlite3`.' \
  'The artifact does not open a remote connection in HW.' \
  'The artifact does not mutate CT202.' \
  '/srv/edge-controller/data/edge_queue.sqlite3' \
  'Future target table count:' \
  '`39`' \
  '`credit_ledger`' \
  '`user_credit_wallets`' \
  '`workers`' \
  '`credit_reservations`' \
  'CT202 status `running`' \
  'CT202 hostname `edge-controller`' \
  'CT202 onboot `0`' \
  'public routes unchanged' \
  'CT202 cutover gate CLOSED' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'Preservation must include no row content and no SQL dump.' \
  'Future candidate rebuild action design, not executed' \
  'Do not import live laptop data.' \
  'The artifact contains no:' \
  'The artifact does not define the real candidate rebuild approval phrase.' \
  'Phase 14J-HX - CT202 candidate rebuild apply artifact rehearsal, no apply' \
  'APPROVE_PHASE_14J_HX_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_REHEARSAL_NO_APPLY' \
  'The CT202 controller cutover readiness gate remains CLOSED.' \
  'The CT202 candidate mutation gate remains CLOSED.' \
  'Laptop controller and laptop-local DB remain live authority.' \
  'CT202 remains private candidate only.'
do
  require_present "$DOC" "$needle"
done

for needle in \
  'REQUIRED_APPROVAL="APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY"' \
  'MODE=candidate_rebuild_apply_artifact_no_apply' \
  'NO real candidate rebuild approval phrase defined' \
  'NO restore' \
  'NO rebuild' \
  'NO cutover/apply' \
  'NO CT202 schema apply' \
  'NO SQLite open with sqlite3' \
  'NO SQL dump' \
  'NO systemctl start' \
  'NO systemctl enable' \
  'TARGET_DB="/srv/edge-controller/data/edge_queue.sqlite3"' \
  'EXPECTED_TARGET_TABLE_COUNT="39"' \
  'HP_SCRIPT="ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh"' \
  'HR_SCRIPT="ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh"' \
  'HT_SCRIPT="ops/rehearsal/phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply.sh"' \
  'This artifact contains no rebuild implementation.' \
  'This artifact does not define the real candidate rebuild approval phrase.' \
  'PASS: no-apply candidate rebuild artifact ran safely'
do
  require_present "$SCRIPT" "$needle"
done

for file in "$DOC" "$SCRIPT"; do
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
    require_absent "$file" "$needle"
  done
done

echo
echo "=== run HW no-apply artifact smoke ==="
APC_HW_APPROVAL="APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
bash "$SCRIPT" | tee /tmp/apc-hw-artifact-smoke-output.txt

grep -Fq 'PASS: no-apply candidate rebuild artifact ran safely' /tmp/apc-hw-artifact-smoke-output.txt
grep -Fq 'PASS: future candidate rebuild boundary summarized' /tmp/apc-hw-artifact-smoke-output.txt
grep -Fq 'PASS: preservation design summarized' /tmp/apc-hw-artifact-smoke-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-hw-artifact-smoke-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-hw-artifact-smoke-output.txt

echo "PASS: ${PHASE}"
