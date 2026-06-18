# Phase 14J-GH-R0 - CT202 fresh SQLite bootstrap inspection and plan, no apply

PHASE_14J_GH_R0_CT202_FRESH_SQLITE_BOOTSTRAP_PLAN_NO_RUNTIME_ACTIVATION

PHASE_14J_GH_R0_RESULT=ct202_fresh_sqlite_bootstrap_plan_recorded_no_apply

This phase inspected CT 202 and recorded the fresh SQLite bootstrap plan.

No fresh database was created in this phase.

## Current state

PHASE_14J_GH_R0_CT_ID=202

PHASE_14J_GH_R0_HOSTNAME=edge-controller

PHASE_14J_GH_R0_STATUS=running

CT 202 has:

- tracked controller code copied default-off
- Python venv installed
- requirements.txt dependencies installed
- no controller runtime active
- no edge-queue-controller systemd service
- no authoritative data role

## Design decision

PHASE_14J_GH_R0_BOOTSTRAP_DECISION=fresh_sqlite_on_ct202_local_disk_first

The next apply phase should create a fresh non-authoritative SQLite database on CT 202 local disk, not on CT 201 and not over a network mount.

Target DB path for the next apply phase:

/srv/edge-controller/data/edge_queue.sqlite3

The CT202 controller should eventually use:

EDGE_QUEUE_SQLITE_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3

## Bootstrap rule

The fresh CT202 DB may be empty/default/bootstrap-only because current laptop data is mostly test/fake data and login is not production-stable.

The laptop-local edge_queue.sqlite3 remains live authority until a later explicit cutover.

## Next apply phase

Required approval phrase for the next apply phase:

APPROVE_PHASE_14J_GH_CREATE_CT202_FRESH_SQLITE_DB_DEFAULT_OFF

The next apply phase may:

- create /srv/edge-controller/data/edge_queue.sqlite3 on CT 202
- use the safest available repo schema/bootstrap path found during inspection
- run sqlite quick_check
- record table/index counts
- avoid importing laptop user data by default
- avoid activating controller runtime
- avoid creating systemd services
- avoid public routes

## Not performed

- no fresh DB creation
- no controller runtime activation
- no systemd service creation
- no systemd enable
- no systemd start
- no laptop controller stop
- no data migration
- no live DB mutation
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no Phase 14J-AG apply wrapper rerun

NEXT_SAFE_PHASE=phase_14j_gh_create_ct202_fresh_sqlite_db_default_off_requires_explicit_approval
