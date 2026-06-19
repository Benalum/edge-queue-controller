#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mq-a-smoke-backtick-hygiene-repair-no-apply"
DOC="docs/${PHASE}.md"
MQ_SMOKE="ops/smoke/check-phase-14j-mq-ct203-private-storage-backup-execution-plan-no-apply.sh"

echo "=== smoke: ${PHASE} ==="

require_doc() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required doc pattern: $pattern"
    exit 1
  fi
}

test -f "$DOC"
test -x "$MQ_SMOKE"

require_doc "Phase 14J-MQ-A"
require_doc "Smoke Backtick Hygiene Repair No-Apply"
require_doc "97d7009"
require_doc "controller-phase-14j-mq-ct203-private-storage-backup-execution-plan-no-apply-2026-06-18"
require_doc "PASS_PHASE_14J_MQ_CT203_PRIVATE_STORAGE_BACKUP_EXECUTION_PLAN_NO_APPLY_DONE"
require_doc "mq_smoke_command_substitution_warning=absent"
require_doc "APPROVE_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART"
require_doc "No SSH connection"
require_doc "storage unlock/mount/format/key/crypttab/fstab mutation"
require_doc "DB backup creation"
require_doc "PASS_PHASE_14J_MQ_A_SMOKE_BACKTICK_HYGIENE_REPAIR_NO_APPLY_DONE"

if ! grep -Fq 'require '\''Create one timestamped backup directory under `/srv/apc-private-data/backups/ct203`'\''' "$MQ_SMOKE"; then
  echo "FAIL: repaired MQ smoke single-quoted assertion missing"
  exit 1
fi

echo "PASS: 14J-MQ-A smoke hygiene repair evidence present"
echo "PASS_${PHASE}"
