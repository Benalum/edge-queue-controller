#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-nc-r2-worker-model-inventory-record-read-only"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "COMPLETED READ-ONLY INVENTORY." "$DOC"
grep -Fq "did not wake PVESO" "$DOC"
grep -Fq "did not" "$DOC"
grep -Fq "private_storage_mount_state_host: \`not_mounted\`" "$DOC"
grep -Fq "private_storage_mapper_state: \`absent\`" "$DOC"
grep -Fq "private_storage_crypt_status: \`inactive\`" "$DOC"
grep -Fq "edge_queue_controller_service_active: \`active\`" "$DOC"
grep -Fq "sqlite_integrity_check: \`ok\`" "$DOC"
grep -Fq "worker_queue_model_related_tables:" "$DOC"
grep -Fq "workers_columns:" "$DOC"
grep -Fq "worker_role" "$DOC"
grep -Fq "worker_lane" "$DOC"
grep -Fq "accepts_lane_jobs" "$DOC"
grep -Fq "Worker/model re-entry remains blocked behind staged approvals." "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_NC_R2_WORKER_MODEL_INVENTORY_RECORD_READ_ONLY_DONE" "$DOC"

echo "PASS: worker/model inventory record contains required evidence and gates"
