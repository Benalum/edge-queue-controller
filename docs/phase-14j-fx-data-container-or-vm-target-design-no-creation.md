# Phase 14J-FX - Data container or VM target design, no creation

PHASE_14J_FX_DATA_CONTAINER_OR_VM_TARGET_DESIGN_NO_CREATION

PHASE_14J_FX_RESULT=data_target_design_recorded_no_creation

This phase records the recommended target direction for moving the live SQLite authority off the laptop later.

No container, VM, storage volume, migration, service reload, runtime config change, or live DB mutation occurs in this phase.

## Starting checkpoint

Previous phase:

- Phase 14J-FW
- Commit: f4ab0ce
- Tag: controller-phase-14j-fw-default-preserving-controller-db-path-env-override-no-runtime-reload-2026-06-17

## Current facts

The project has now proven:

- website-edge VM handles static public website hosting;
- live controller/platform authority is edge_queue.sqlite3;
- persistent SQLite backup and restore verification scripts exist;
- controller DB path is env-configurable while preserving default edge_queue.sqlite3;
- no runtime apply has occurred yet.

## Recommended target choice

Recommended target type for first data move:

PHASE_14J_FX_RECOMMENDED_TARGET=private_lxc_data_container_not_public_vm

Reasoning:

- SQLite data authority does not need public exposure.
- A private LXC data container is lighter than a full VM.
- A data-only LXC keeps website-edge separate from database authority.
- A private LXC can later host a durable mounted path for edge_queue.sqlite3 backups and restore validation.
- The controller should not move until this data target is proven.

## Proposed future data container role

Future data container role:

- private storage host for SQLite backup artifacts;
- private restore validation target;
- later durable SQLite authority only after explicit apply;
- future database service candidate if SQLite is later migrated to Postgres;
- no public routes;
- no Cloudflare tunnel;
- no model calls;
- no worker process;
- no Proxmox management exposure.

## Non-goals

The data container must not host:

- public website;
- controller API;
- queue scheduler;
- worker process;
- model runtime;
- CT101 controls;
- Proxmox controls;
- Cloudflare tunnel;
- public auth/control routes.

## Required before creation

Before creating a data LXC, a later phase must define:

1. CT ID and hostname;
2. storage pool and mount path;
3. backup destination path;
4. restore validation path;
5. file owner and mode policy;
6. network access boundary;
7. no-public-route proof;
8. snapshot or rollback method;
9. exact rollback to laptop-local edge_queue.sqlite3;
10. explicit approval phrase.

## Required before live cutover

Before any live DB cutover:

1. run persistent SQLite backup;
2. copy backup to data target;
3. verify backup on target;
4. run restore drill on target;
5. stop or quiesce controller writes in an approved maintenance window;
6. set EDGE_QUEUE_SQLITE_DB_PATH in controller environment;
7. restart/reload only in a separately approved apply phase;
8. validate controller health and DB integrity;
9. keep rollback to laptop-local edge_queue.sqlite3 ready.

## Recommended next phase

NEXT_SAFE_PHASE=phase_14j_fy_read_only_proxmox_data_target_inventory_no_creation

The next phase should inspect available Proxmox-safe target choices without creating anything and without printing raw private IPs.

## Still not performed

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
- no Phase 14J-AG apply wrapper rerun
