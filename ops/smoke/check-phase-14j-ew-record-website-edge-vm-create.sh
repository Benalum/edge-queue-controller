#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ew-record-website-edge-vm-create"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-EW smoke: record website-edge VM create ==="

test -f "$DOC"
echo "PASS: EW doc exists"

for marker in \
  "PHASE_14J_EW_RECORD_WEBSITE_EDGE_VM_CREATE" \
  "MUTATION_SCOPE=docs_smoke_only_record_approved_vm_creation" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_EV_RESULT=ready_for_explicit_vm_create_approval" \
  "FIRST_EW_CREATE_ATTEMPT_RESULT=failed_before_vm_create" \
  "FIRST_EW_CREATE_ATTEMPT_REASON=proxmox_cluster_not_ready_no_quorum" \
  "PVE_BEFORE_EXPECTED_VOTES=3" \
  "PVE_BEFORE_TOTAL_VOTES=1" \
  "PVE_BEFORE_QUORUM=2" \
  "PVE_BEFORE_QUORATE=no" \
  "PVE_EXPECTED_VOTES_SET_TO_1_FOR_CREATE=yes" \
  "PVE_AFTER_EXPECTED_VOTES=1" \
  "PVE_AFTER_TOTAL_VOTES=1" \
  "PVE_AFTER_QUORUM=1" \
  "PVE_AFTER_QUORATE=yes" \
  "WEBSITE_EDGE_VM_CREATE_RESULT=created_stopped" \
  "WEBSITE_EDGE_VM_ID=200" \
  "WEBSITE_EDGE_VM_NAME=website-edge" \
  "WEBSITE_EDGE_VM_STARTED=no" \
  "WEBSITE_EDGE_VM_OS_INSTALLED=no" \
  "WEBSITE_EDGE_VM_MEMORY_2048_CONFIRMED=yes" \
  "WEBSITE_EDGE_VM_CORES_2_CONFIRMED=yes" \
  "PVE_STORAGE_WARNING_THIN_POOL_AUTOEXTEND_NOT_CONFIGURED=yes" \
  "PVE_STORAGE_WARNING_THIN_VOLUME_SUM_EXCEEDS_THIN_POOL_SIZE=yes" \
  "PVE_STORAGE_WARNING_REVIEW_REQUIRED_BEFORE_OS_INSTALL=yes" \
  "WEBSITE_EDGE_VM_SHOULD_NOT_START_BEFORE_STORAGE_REVIEW=yes" \
  "CLOUDFLARE_CUTOVER_PERFORMED=no" \
  "TAILSCALE_POLICY_MUTATION_PERFORMED=no" \
  "FIREWALL_MUTATION_PERFORMED=no" \
  "WORKER_START_PERFORMED=no" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "PRODUCTION_DB_JOB_MUTATION_PERFORMED=no" \
  "CT101_CALL_PERFORMED=no" \
  "MODEL_OLLAMA_ENDPOINT_CALL_PERFORMED=no" \
  "CONTROLLER_QUEUE_MIGRATION_PERFORMED=no" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "REQUIRE_STORAGE_WARNING_REVIEW_BEFORE_OS_INSTALL=yes" \
  "REQUIRE_EXPLICIT_OS_INSTALL_APPROVAL=yes" \
  "PHASE_14J_EW_RESULT=website_edge_vm_created_stopped_and_recorded" \
  "NEXT_SAFE_PHASE=website_vm_storage_warning_review_before_os_install"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-EW website-edge VM create record smoke passed"
