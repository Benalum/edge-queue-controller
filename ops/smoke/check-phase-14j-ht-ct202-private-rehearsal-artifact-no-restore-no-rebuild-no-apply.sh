#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply"
DOC="docs/${PHASE}.md"
SCRIPT="ops/rehearsal/${PHASE}.sh"

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
  'Phase 14J-HT - CT202 private rehearsal artifact, no restore/no rebuild/no apply' \
  'Previous checkpoint: Phase 14J-HS at commit `bac3a4b`' \
  'APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY' \
  'ops/rehearsal/phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply.sh' \
  'remote read-only CT202 posture verification' \
  'remote read-only HM/HN backup artifact verification' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'HP no-apply artifact runs without applying' \
  'HR no-restore artifact runs without restoring' \
  'contains no' \
  'Phase 14J-HU - CT202 private rehearsal result review and pre-apply risk gate, no apply' \
  'APPROVE_PHASE_14J_HU_CT202_PRIVATE_REHEARSAL_RESULT_REVIEW_PRE_APPLY_RISK_GATE_NO_APPLY' \
  'CT202 controller cutover readiness gate remains CLOSED'
do
  require_present "$DOC" "$needle"
done

for needle in \
  'REQUIRED_APPROVAL="APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY"' \
  'MODE=private_rehearsal_no_restore_no_rebuild_no_apply' \
  'NO restore' \
  'NO rebuild' \
  'NO cutover/apply' \
  'NO CT202 schema apply' \
  'NO SQLite open with sqlite3' \
  'NO SQL dump' \
  'NO systemctl start' \
  'NO systemctl enable' \
  'HP_SCRIPT="ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh"' \
  'HR_SCRIPT="ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh"' \
  'EXPECTED_DB_SIZE="262144"' \
  'EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"' \
  'PASS: private rehearsal artifact ran safely' \
  'PASS: no restore/rebuild/schema apply performed'
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
echo "=== run HT private rehearsal artifact smoke ==="
APC_HT_APPROVAL="APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
APC_HT_REMOTE_READONLY="1" \
bash "$SCRIPT" | tee /tmp/apc-ht-artifact-smoke-output.txt

grep -Fq 'PASS: private rehearsal artifact ran safely' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: HP no-apply artifact ran' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: HR no-restore artifact ran' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: CT202 read-only posture checks passed' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: HM/HN backup artifact checks passed' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-ht-artifact-smoke-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-ht-artifact-smoke-output.txt

echo "PASS: ${PHASE}"
