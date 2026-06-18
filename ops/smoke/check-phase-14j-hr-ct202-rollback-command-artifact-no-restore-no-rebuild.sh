#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild"
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
  'Phase 14J-HR - CT202 rollback command artifact, no restore/no rebuild' \
  'Previous checkpoint: Phase 14J-HQ at commit `00cfa1e`' \
  'APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD' \
  'opens no remote connection in HR' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'Required CT202 posture before any future restore' \
  'Planned rollback order, design only' \
  'contains no' \
  'Phase 14J-HS - CT202 private rehearsal plan, no restore/no rebuild/no apply' \
  'APPROVE_PHASE_14J_HS_CT202_PRIVATE_REHEARSAL_PLAN_NO_RESTORE_NO_REBUILD_NO_APPLY' \
  'CT202 controller cutover readiness gate remains CLOSED'
do
  require_present "$DOC" "$needle"
done

for needle in \
  'REQUIRED_APPROVAL="APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD"' \
  'MODE=no_restore_rollback_plan_check_only' \
  'NO restore' \
  'NO rebuild' \
  'NO cutover/apply' \
  'NO CT202 schema apply' \
  'NO SQLite open with sqlite3' \
  'NO SQL dump' \
  'NO systemctl start' \
  'NO systemctl enable' \
  'EXPECTED_DB_SIZE="262144"' \
  'EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"' \
  'This artifact contains no restore implementation.' \
  'This artifact opens no remote connection in HR.' \
  'PASS: no-restore rollback command artifact ran safely'
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
echo "=== run HR no-restore artifact smoke ==="
APC_HR_APPROVAL="APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
bash "$SCRIPT" | tee /tmp/apc-hr-artifact-smoke-output.txt

grep -Fq 'PASS: no-restore rollback command artifact ran safely' /tmp/apc-hr-artifact-smoke-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-hr-artifact-smoke-output.txt
grep -Fq 'PASS: no service start/enable or onboot mutation' /tmp/apc-hr-artifact-smoke-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-hr-artifact-smoke-output.txt

echo "PASS: ${PHASE}"
