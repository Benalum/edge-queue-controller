#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ex-website-vm-storage-review-and-os-install-gate"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-EX smoke: website VM storage review and OS install gate ==="

test -f "$DOC"
echo "PASS: EX doc exists"

for marker in \
  "PHASE_14J_EX_WEBSITE_VM_STORAGE_REVIEW_AND_OS_INSTALL_GATE" \
  "MUTATION_SCOPE=docs_smoke_only_storage_review_and_os_install_gate" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_EW_RESULT=website_edge_vm_created_stopped_and_recorded" \
  "WEBSITE_EDGE_VM_CREATE_RESULT=created_stopped" \
  "WEBSITE_EDGE_VM_ID=200" \
  "WEBSITE_EDGE_VM_STARTED=no" \
  "WEBSITE_EDGE_VM_OS_INSTALLED=no" \
  "STORAGE_WARNING_REVIEW_RESULT=completed_read_only" \
  "WEBSITE_VM_EXISTS=yes" \
  "WEBSITE_VM_STATUS=stopped" \
  "WEBSITE_VM_DISK_SIZE_20G=yes" \
  "PVE_STORAGE_AVAILABLE_KIB=73466815" \
  "PVE_ROOT_AVAILABLE_MIB=25753" \
  "PVE_VG_FREE_GIB=13.63" \
  "PVE_THIN_POOL_SIZE_GIB=49.17" \
  "PVE_THIN_POOL_DATA_PERCENT=8.65" \
  "PVE_THIN_POOL_METADATA_PERCENT=1.70" \
  "PVE_THIN_POOL_AUTOEXTEND_THRESHOLD=unknown" \
  "PVE_STORAGE_WARNING_REVIEW_COMPLETED=yes" \
  "PVE_STORAGE_WARNING_ACCEPTED_FOR_INITIAL_SMALL_WEBSITE_VM=yes" \
  "WEBSITE_VM_20G_THIN_DISK_ACCEPTED_FOR_INITIAL_OS_INSTALL=yes" \
  "WEBSITE_VM_STORAGE_MONITORING_REQUIRED=yes" \
  "DO_NOT_ADD_ADDITIONAL_VMS_OR_DISKS_WITHOUT_STORAGE_REVIEW=yes" \
  "WEBSITE_VM_OS_INSTALL_ALLOWED_IN_THIS_PHASE=no" \
  "WEBSITE_VM_START_ALLOWED_IN_THIS_PHASE=no" \
  "WEBSITE_VM_OS_INSTALL_REQUIRES_EXPLICIT_APPROVAL=yes" \
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
  "REQUIRE_EXPLICIT_OS_INSTALL_APPROVAL=yes" \
  "PHASE_14J_EX_RESULT=storage_review_completed_and_20g_disk_accepted_for_initial_os_install" \
  "NEXT_SAFE_PHASE=website_vm_os_install_after_explicit_approval"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-EX storage review and OS install gate smoke passed"
