#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ev-website-edge-vm-design"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-EV smoke: website-edge VM design ==="

test -f "$DOC"
echo "PASS: EV doc exists"

for marker in \
  "PHASE_14J_EV_WEBSITE_EDGE_VM_DESIGN" \
  "MUTATION_SCOPE=docs_smoke_only_website_vm_design" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_EU_RESULT=ready_for_website_vm_design" \
  "LOW_POWER_PROXMOX_HOST_READINESS=ready_for_design" \
  "TAILSCALE_HARDENING_STATUS=parked" \
  "ARCHITECTURE_PIVOT=move_production_website_off_laptop" \
  "WEBSITE_EDGE_VM_ROLE=public_website_edge" \
  "WEBSITE_EDGE_VM_ISOLATION_MODEL=vm" \
  "WEBSITE_EDGE_VM_TARGET_HOST=low_power_proxmox" \
  "WEBSITE_EDGE_VM_NAME=website-edge" \
  "WEBSITE_EDGE_VM_ID_RECOMMENDATION=choose_unused_200_range_id" \
  "WEBSITE_EDGE_VM_CPU_VCPU=2" \
  "WEBSITE_EDGE_VM_MEMORY_MIB=2048" \
  "WEBSITE_EDGE_VM_DISK_GIB=20" \
  "WEBSITE_EDGE_VM_NETWORK_BRIDGE=existing_single_bridge" \
  "WEBSITE_EDGE_VM_IMAGE_REQUIRED=yes" \
  "WEBSITE_EDGE_VM_ISO_COUNT_CURRENT=0" \
  "WEBSITE_EDGE_VM_INSTALL_MEDIA_REQUIRED=yes" \
  "WEBSITE_EDGE_DEPLOYMENT_SOURCE=current_git_repo_initially" \
  "WEBSITE_EDGE_REPO_MODE=clone_current_edge_queue_controller_then_run_public_wrapper_only" \
  "WEBSITE_EDGE_RUN_PUBLIC_WRAPPER=yes" \
  "WEBSITE_EDGE_RUN_FULL_CONTROLLER=no" \
  "WEBSITE_EDGE_RUN_QUEUE=no" \
  "WEBSITE_EDGE_RUN_WORKERS=no" \
  "WEBSITE_EDGE_RUN_PROXMOX_MANAGEMENT=no" \
  "WEBSITE_EDGE_VM_HAS_PROXMOX_MANAGEMENT_ACCESS=no" \
  "WEBSITE_EDGE_VM_HAS_WORKER_START_ACCESS=no" \
  "WEBSITE_EDGE_VM_HAS_RUNTIME_ACTIVATION_ACCESS=no" \
  "WEBSITE_EDGE_VM_PUBLIC_USERS_CAN_CONTROL_INFRASTRUCTURE=no" \
  "CLOUDFLARE_TEST_ROUTE_REQUIRED_BEFORE_PRODUCTION=yes" \
  "CLOUDFLARE_PRODUCTION_CUTOVER_ALLOWED_IN_EV=no" \
  "CLOUDFLARE_PRODUCTION_CUTOVER_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "ROLLBACK_PLAN_REQUIRED=yes" \
  "ROLLBACK_BEFORE_CUTOVER_KEEP_LAPTOP_PATH=yes" \
  "REQUIRE_EXPLICIT_VM_CREATE_APPROVAL=yes" \
  "REQUIRE_INSTALL_MEDIA_DECISION=yes" \
  "REQUIRE_VM_ID_CONFIRMATION=yes" \
  "REQUIRE_NETWORK_MODE_CONFIRMATION=yes" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "FIREWALL_MUTATION=not_performed" \
  "TAILSCALE_ACL_MUTATION=not_performed" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=not_performed" \
  "CLOUDFLARE_ROUTE_MUTATION=not_performed" \
  "VM_CREATION=not_performed" \
  "CONTAINER_CREATION=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "WEBSITE_EDGE_VM_DESIGN_RESULT=ready_for_explicit_vm_create_approval" \
  "NEXT_SAFE_PHASE=website_vm_create_after_explicit_approval"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-EV website-edge VM design smoke passed"
