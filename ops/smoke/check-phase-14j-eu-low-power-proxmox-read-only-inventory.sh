#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eu-low-power-proxmox-read-only-inventory"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-EU smoke: low-power Proxmox read-only inventory ==="

test -f "$DOC"
echo "PASS: EU doc exists"

for marker in \
  "PHASE_14J_EU_LOW_POWER_PROXMOX_READ_ONLY_INVENTORY" \
  "MUTATION_SCOPE=docs_smoke_only_record_sanitized_low_power_proxmox_inventory" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_ET_RESULT=ready_for_low_power_proxmox_inventory" \
  "TAILSCALE_HARDENING_STATUS=parked" \
  "ARCHITECTURE_PIVOT=move_production_website_off_laptop" \
  "LOW_POWER_PROXMOX_INVENTORY_RESULT=completed_read_only" \
  "LOW_POWER_PROXMOX_VERSION_PRESENT=yes" \
  "LOW_POWER_PROXMOX_VERSION_SUMMARY=pve_manager_9_1_5" \
  "LOW_POWER_PROXMOX_QM_PRESENT=yes" \
  "LOW_POWER_PROXMOX_PCT_PRESENT=yes" \
  "LOW_POWER_PROXMOX_TAILSCALED_ACTIVE=active" \
  "LOW_POWER_PROXMOX_TAILSCALED_ENABLED=enabled" \
  "LOW_POWER_PROXMOX_TAILSCALE_PRESENT=yes" \
  "LOW_POWER_PROXMOX_TAILSCALE_IPV4_PRESENT=yes" \
  "LOW_POWER_PROXMOX_TAILSCALE_IPV6_PRESENT=yes" \
  "LOW_POWER_PROXMOX_CPU_THREADS=8" \
  "LOW_POWER_PROXMOX_MEM_TOTAL_MIB=7787" \
  "LOW_POWER_PROXMOX_STORAGE_AVAILABLE_KIB=76319715" \
  "LOW_POWER_PROXMOX_VM_COUNT=0" \
  "LOW_POWER_PROXMOX_CT_COUNT=0" \
  "LOW_POWER_PROXMOX_TEMPLATE_CACHE_COUNT=1" \
  "LOW_POWER_PROXMOX_ISO_COUNT=0" \
  "LOW_POWER_PROXMOX_CLOUD_INIT_CMD_PRESENT=no" \
  "LOW_POWER_PROXMOX_BRIDGE_IFACE_COUNT=1" \
  "LOW_POWER_PROXMOX_TIME_NTP_SYNCHRONIZED=yes" \
  "WEBSITE_VM_HOST_READINESS=ready_for_design" \
  "WEBSITE_VM_HOST_CAPACITY_ASSESSMENT=small_website_vm_feasible" \
  "WEBSITE_VM_EXPECTED_INITIAL_SPEC=vCPU_2_RAM_2GiB_DISK_20GiB" \
  "WEBSITE_VM_ISO_OR_CLOUD_IMAGE_REQUIRED=yes" \
  "REQUIRE_WEBSITE_VM_DESIGN_BEFORE_VM_CREATE=yes" \
  "REQUIRE_EXPLICIT_WEBSITE_VM_CREATE_APPROVAL=yes" \
  "REQUIRE_NO_CLOUDFLARE_PRODUCTION_CUTOVER_DURING_VM_CREATE=yes" \
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
  "LOW_POWER_PROXMOX_READ_ONLY_INVENTORY_RESULT=ready_for_website_vm_design" \
  "NEXT_SAFE_PHASE=website_vm_design"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-EU low-power Proxmox inventory smoke passed"
