# Phase 14J-FZ - Data LXC creation plan, no apply

PHASE_14J_FZ_DATA_LXC_CREATION_PLAN_NO_APPLY

PHASE_14J_FZ_RESULT=data_lxc_creation_plan_recorded_no_apply

This phase records the plan for a future private Proxmox LXC data container.

No container was created. No VM was created. No Proxmox config was changed. No data was migrated. No live runtime config changed.

## Previous checkpoint

- Previous phase: Phase 14J-FY
- Previous commit: 8f72b81
- Previous tag: controller-phase-14j-fy-proxmox-data-target-inventory-no-creation-2026-06-17

## Planned target

PHASE_14J_FZ_PLANNED_CT_ID=201

PHASE_14J_FZ_PLANNED_HOSTNAME=edge-data

PHASE_14J_FZ_PLANNED_KIND=private_lxc_data_container

Planned role:

- private storage and restore-validation target for controller SQLite backups
- future data authority candidate only after a separate explicit runtime cutover
- no public route
- no Cloudflare tunnel
- no controller API
- no queue scheduler
- no worker process
- no model runtime
- no Proxmox management exposure

## Recommended creation shape

Recommended Proxmox target:

- host: pveso
- CT ID: 201
- hostname: edge-data
- type: LXC
- network: private LAN or Tailscale-only administrative access
- public exposure: none
- Cloudflare tunnel: none
- autostart: disabled until validated
- unprivileged container: preferred if compatible
- root disk storage: local-lvm
- data/backup storage: data-2tb
- initial root filesystem size: small, expandable
- initial backup path: /srv/edge-data/sqlite-backups
- restore drill path: /srv/edge-data/restore-drills
- live SQLite path, later only: /srv/edge-data/live/edge_queue.sqlite3

## Initial package plan

Install only minimal packages needed for private data storage and restore verification:

- sqlite3
- python3
- rsync
- openssh-server if not already present
- ca-certificates
- curl only if needed for OS/package maintenance

Do not install:

- Docker
- Node/npm
- Ollama
- cloudflared
- nginx
- model runtimes
- worker services
- controller services

## File ownership and permissions plan

Recommended paths:

- /srv/edge-data
- /srv/edge-data/sqlite-backups
- /srv/edge-data/restore-drills
- /srv/edge-data/live

Recommended permissions:

- directory owner decided in creation phase
- private backup directories should not be world-readable
- backup files should be 0600 or equivalent private mode
- manifests should avoid secrets, raw IPs, and auth URLs

## Creation preflight required later

A later apply phase must verify before any creation:

1. CT ID 201 is still available.
2. Storage pools are still active.
3. No public route is attached.
4. No Cloudflare route is created.
5. No Proxmox management port is exposed.
6. The selected OS template is present.
7. Snapshot or rollback plan is defined.
8. Explicit approval phrase is provided.

## Future apply approval phrase

Required approval phrase for a later creation phase:

APPROVE_PHASE_14J_GA_CREATE_PRIVATE_EDGE_DATA_LXC_201

This phrase is not approval in this phase. It is documented only for a later apply phase.

## Boundary

Still not performed:

- no container creation
- no VM creation
- no pct create
- no pct start
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

NEXT_SAFE_PHASE=phase_14j_ga_private_edge_data_lxc_creation_apply_requires_explicit_approval
