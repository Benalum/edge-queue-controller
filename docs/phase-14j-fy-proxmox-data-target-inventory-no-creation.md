# Phase 14J-FY - Proxmox data target inventory, no creation

PHASE_14J_FY_PROXMOX_DATA_TARGET_INVENTORY_NO_CREATION

PHASE_14J_FY_RESULT=proxmox_data_target_inventory_recorded_no_creation

This phase records the read-only Proxmox inventory used to plan a future private data LXC for the AI Platform Control controller SQLite authority.

No container, VM, storage volume, migration, service reload, runtime config change, or live DB mutation occurred.

## Starting checkpoint

Previous phase:

- Phase 14J-FX
- Commit: d47df12
- Tag: controller-phase-14j-fx-data-container-or-vm-target-design-no-creation-2026-06-17

## Reachability result

Proxmox host SSH access was confirmed using the saved Tailscale target.

The short hostname and full Tailscale DNS name were not reliable from the laptop during FY-R1, so the target was resolved through Tailscale status and used internally without recording raw IPs.

No raw IPs or auth URLs are recorded in this document.

## Proxmox inventory summary

Observed host:

- hostname: pveso
- Proxmox version: pve-manager 9.1.5
- existing VM 101 named llms was stopped

Observed storage pools:

- data-2tb: active, about 40 percent used
- local: active, about 16 percent used
- local-lvm: active, about 36 percent used

Observed candidate IDs:

- 201 available
- 202 available
- 203 available
- 204 available
- 205 available
- 206 available
- 207 available
- 208 available
- 209 available
- 210 available
- 211 available
- 212 available
- 213 available
- 214 available
- 215 available

## Recommended target decision

PHASE_14J_FY_RECOMMENDED_CT_ID=201

PHASE_14J_FY_RECOMMENDED_TARGET_KIND=private_lxc_data_container

Recommended future hostname:

- edge-data

Recommended future purpose:

- private data-only LXC for SQLite backup storage and restore validation
- later durable SQLite authority only after explicit apply
- no public route
- no Cloudflare tunnel
- no controller API
- no queue scheduler
- no worker process
- no model runtime
- no Proxmox public exposure

## Boundary

This phase only records inventory and target direction.

Still not performed:

- no container creation
- no VM creation
- no data migration
- no live DB mutation
- no controller/queue migration
- no service restart/reload
- no runtime config change
- no systemd mutation
- no env file mutation
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no raw IP recording
- no auth URL recording
- no Phase 14J-AG apply wrapper rerun

## Required before creation

Before creating CT 201, a later phase must define:

1. LXC template choice
2. root disk storage choice
3. data/backup path
4. unprivileged/privileged decision
5. network mode and no-public-route proof
6. initial packages
7. file owner/mode policy
8. snapshot/rollback plan
9. explicit approval phrase

NEXT_SAFE_PHASE=phase_14j_fz_data_lxc_creation_plan_no_apply
