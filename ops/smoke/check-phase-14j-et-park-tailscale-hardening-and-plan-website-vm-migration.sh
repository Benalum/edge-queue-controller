#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-et-park-tailscale-hardening-and-plan-website-vm-migration"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-ET smoke: park Tailscale hardening and plan website VM migration ==="

test -f "$DOC"
echo "PASS: ET doc exists"

for marker in \
  "PHASE_14J_ET_PARK_TAILSCALE_HARDENING_AND_PLAN_WEBSITE_VM_MIGRATION" \
  "MUTATION_SCOPE=docs_smoke_only_architecture_migration_plan" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_ES_RESULT=ready_for_final_manual_apply_or_post_change_validation_gate" \
  "TAILSCALE_HARDENING_STATUS=parked" \
  "ARCHITECTURE_PIVOT=move_production_website_off_laptop" \
  "LOW_POWER_PROXMOX_HOST_CONNECTED_TO_TAILSCALE=yes" \
  "WEBSITE_EDGE_TARGET=vm_on_low_power_proxmox" \
  "WEBSITE_EDGE_ISOLATION_MODEL=vm_for_public_edge" \
  "CONTROLLER_QUEUE_TARGET=private_container_or_vm_later" \
  "AI_RUNTIME_TARGET=private_llms_ct101_runtime" \
  "LAPTOP_TARGET_ROLE=admin_dev_only" \
  "PVESO_TARGET_ROLE=private_heavy_ai_runtime" \
  "MIGRATION_STAGE_2=low_power_proxmox_read_only_inventory" \
  "MIGRATION_STAGE_3=website_vm_design" \
  "MIGRATION_STAGE_4=website_vm_create_after_explicit_approval" \
  "WEBSITE_VM_PURPOSE=public_website_edge" \
  "WEBSITE_VM_HAS_PROXMOX_MANAGEMENT_ACCESS=no" \
  "WEBSITE_VM_HAS_WORKER_START_ACCESS=no" \
  "WEBSITE_VM_HAS_RUNTIME_ACTIVATION_ACCESS=no" \
  "CONTROLLER_QUEUE_PRIVATE_ONLY=yes" \
  "PUBLIC_USERS_CAN_CONTROL_INFRASTRUCTURE=no" \
  "REQUIRE_LOW_POWER_PROXMOX_INVENTORY_BEFORE_VM_CREATE=yes" \
  "REQUIRE_WEBSITE_VM_DESIGN_BEFORE_VM_CREATE=yes" \
  "REQUIRE_EXPLICIT_VM_CREATE_APPROVAL=yes" \
  "REQUIRE_CLOUDFLARE_TEST_ROUTE_BEFORE_PRODUCTION_CUTOVER=yes" \
  "REQUIRE_EXPLICIT_PRODUCTION_CUTOVER_APPROVAL=yes" \
  "REQUIRE_NO_TAILSCALE_HARDENING_DURING_WEBSITE_BASELINE=yes" \
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
  "WEBSITE_VM_MIGRATION_PLAN_RESULT=ready_for_low_power_proxmox_inventory" \
  "NEXT_SAFE_PHASE=low_power_proxmox_read_only_inventory"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-ET website VM migration plan smoke passed"
