# Phase 14J-GC-R0 - Controller/data split pivot plan, no apply

PHASE_14J_GC_R0_CONTROLLER_DATA_SPLIT_PIVOT_PLAN_NO_APPLY

PHASE_14J_GC_R0_RESULT=controller_data_split_pivot_plan_recorded_no_apply

This phase records a planning pivot for a faster and safer migration path.

Instead of first trying to preserve and move the mostly test/fake laptop SQLite database, the project will create a separate private controller/queue container and build it cleanly. The current login system is not considered production-stable, so a fresh controller database or selective import is acceptable later.

No infrastructure was created or started in this phase.

## Current containers and roles

VM 200 website-edge:

- public static website and wrapper edge
- no controller
- no queue
- no database authority
- no worker
- no model runtime

CT 201 edge-data:

- private data/backups/restore-drill container candidate
- already created
- currently stopped
- not live DB authority
- no public route
- no Cloudflare tunnel

Planned CT 202 edge-controller:

- private controller and queue container
- future controller API home
- future queue/scheduler home
- future auth/login repair target
- should own its local live SQLite database at first
- should not use a network-mounted SQLite file from CT 201

CT 101 llms:

- remains worker/model container later
- not needed for controller/container buildout
- no model calls in this pivot phase

## Key design decision

PHASE_14J_GC_R0_SQLITE_DECISION=controller_container_local_sqlite_first

The live SQLite database should live locally inside the future controller/queue container during the first migration.

CT 201 edge-data should initially be used for:

- backups
- restore drills
- future data-service planning
- future Postgres candidate

CT 201 should not be used as a network file host for a live SQLite file accessed by CT 202.

Reason:

- network-mounted SQLite can create locking/corruption risk
- local SQLite inside CT 202 is faster and safer for the immediate migration
- a true separate data container should use Postgres or another service-style database later

## Migration posture

PHASE_14J_GC_R0_DATA_POSTURE=fresh_or_selective_import_allowed

Because the current database mostly contains fake/test users and login is not working, later phases may choose:

1. fresh SQLite bootstrap in CT 202, or
2. selective import from laptop backup, or
3. full SQLite copy only if explicitly approved

The laptop-local edge_queue.sqlite3 remains live authority until a later explicit cutover.

## Planned next phases

Phase 14J-GD:

- create private edge-controller LXC CT 202
- no runtime activation
- no public route
- no Cloudflare cutover

Phase 14J-GE:

- baseline CT 202 packages only
- Python/venv/git/SQLite tooling
- no Docker, no Node/npm unless separately approved

Phase 14J-GF:

- clone/deploy controller code default-off
- no public route cutover
- no laptop service stop

Phase 14J-GG:

- fresh DB/bootstrap auth repair path
- private-only tests

Phase 14J-GH:

- private controller/queue smokes

Phase 14J-GI:

- route/cutover plan, no apply

## Explicit approval required later

Required approval phrase for CT 202 creation:

APPROVE_PHASE_14J_GD_CREATE_PRIVATE_EDGE_CONTROLLER_LXC_202

This phrase is not approval in this phase. It is only recorded for the later apply phase.

## Not performed

- no container creation
- no pct create
- no pct start
- no data migration
- no live DB mutation
- no controller/queue migration
- no service restart/reload
- no runtime config change
- no laptop systemd mutation
- no laptop env file mutation
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no Phase 14J-AG apply wrapper rerun

NEXT_SAFE_PHASE=phase_14j_gd_private_edge_controller_lxc_creation_requires_explicit_approval
