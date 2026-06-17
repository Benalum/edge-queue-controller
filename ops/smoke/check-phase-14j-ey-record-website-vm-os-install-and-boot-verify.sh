#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ey-record-website-vm-os-install-and-boot-verify"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-EY smoke: record website VM OS install and boot verification ==="

test -f "$DOC"
echo "PASS: EY doc exists"

for marker in \
  "PHASE_14J_EY_RECORD_WEBSITE_VM_OS_INSTALL_AND_BOOT_VERIFY" \
  "MUTATION_SCOPE=docs_smoke_only_record_os_install_and_boot_verify" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_EX_RESULT=storage_review_completed_and_20g_disk_accepted_for_initial_os_install" \
  "PHASE_14J_EY_APPROVAL_RECEIVED=yes" \
  "WEBSITE_VM_START_APPROVED_FOR_OS_INSTALL=yes" \
  "WEBSITE_VM_ID=200" \
  "WEBSITE_VM_START_RESULT=started_for_manual_console_install" \
  "WEBSITE_VM_MANUAL_OS_INSTALL_APPROVED=yes" \
  "WEBSITE_VM_ADMIN_ACCOUNT_CREATED_MANUALLY=yes" \
  "WEBSITE_VM_SECRETS_PRINTED=no" \
  "WEBSITE_VM_OS_BOOT_VERIFY_RESULT=installed_os_login_screen_confirmed" \
  "WEBSITE_VM_EXISTS=yes" \
  "WEBSITE_VM_STATUS=running" \
  "WEBSITE_VM_RUNNING=yes" \
  "WEBSITE_VM_OS_INSTALLED=yes" \
  "WEBSITE_VM_OS_LOGIN_SCREEN_SEEN=yes" \
  "WEBSITE_VM_MEMORY_2048_CONFIRMED=yes" \
  "WEBSITE_VM_CORES_2_CONFIRMED=yes" \
  "WEBSITE_VM_DISK_SIZE_20G=yes" \
  "QEMU_GUEST_AGENT_AVAILABLE=no" \
  "QEMU_GUEST_AGENT_INSTALL_LATER=yes" \
  "PVE_EXPECTED_VOTES_REMAINS_1=yes" \
  "PVE_QUORATE_DURING_VM_START=yes" \
  "WEBSITE_VM_IOTHREAD_WARNING_SEEN=yes" \
  "WEBSITE_VM_IOTHREAD_WARNING_BLOCKING=no" \
  "VM_START_PERFORMED=yes" \
  "OS_INSTALL_PERFORMED=yes" \
  "BOOT_ORDER_CHANGE_PERFORMED=no" \
  "ISO_DETACH_PERFORMED=no" \
  "PACKAGE_INSTALL_PERFORMED=no" \
  "APP_DEPLOYMENT_PERFORMED=no" \
  "GIT_CLONE_PERFORMED=no" \
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
  "REQUIRE_POST_INSTALL_VM_BASELINE_BEFORE_APP_DEPLOY=yes" \
  "PHASE_14J_EY_RESULT=website_vm_os_installed_and_login_screen_confirmed" \
  "NEXT_SAFE_PHASE=website_vm_post_install_baseline"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-EY OS install and boot verification smoke passed"
