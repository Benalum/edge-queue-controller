# Phase 14J-GM - CT202 private system/queue route runtime smoke temporary only

PHASE_14J_GM_CT202_PRIVATE_SYSTEM_QUEUE_ROUTE_RUNTIME_SMOKE_TEMPORARY_ONLY

PHASE_14J_GM_RESULT=ct202_private_system_queue_route_runtime_smoke_passed_temporary_only

The user explicitly approved the temporary private system/queue route runtime smoke with:

APPROVE_PHASE_14J_GM_CT202_PRIVATE_SYSTEM_QUEUE_ROUTE_RUNTIME_SMOKE_TEMPORARY_ONLY

## Verified state

PHASE_14J_GM_CT_ID=202

PHASE_14J_GM_HOSTNAME=edge-controller

PHASE_14J_GM_STATUS=running

PHASE_14J_GM_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3

The final successful GM-R1B smoke used a temporary in-process CT202-only public API key for loopback-only testing.

The key was generated for the process, was not printed, was not committed, was not stored in Source, and was not made persistent.

Verified by GM-R1B:

- temporary Uvicorn bind was 127.0.0.1 only
- temporary Uvicorn port was 17072
- /openapi.json returned HTTP 200
- OpenAPI path count was 147
- OpenAPI system/status/health route count was 55
- OpenAPI queue/job/worker route count was 27
- safe GET probe candidate count was 16
- safe GET probe count was 16
- safe GET system/status/health probe count was 12
- safe GET queue/job/worker probe count was 4
- safe GET 5xx skipped count was 0
- no POST/PUT/PATCH/DELETE route probes were performed
- no job creation was performed
- no queue mutation was performed
- CT202 DB hash stayed unchanged on the settled DB
- CT202 table count stayed 25
- SQLite quick_check passed after the route smoke
- temporary Uvicorn process was stopped
- exact matching temporary Uvicorn process was absent after cleanup
- loopback port listener was absent after stop
- edge-queue-controller systemd service was not created
- edge-queue-controller runtime was not active after the smoke
- laptop controller was not stopped
- no data was imported from the laptop DB

## Prior GM discovery

The first GM-R1A smoke found the route inventory and GET probes worked, but the DB file hash changed after GET probes.

A cleanup/diagnostic pass showed:

- no temporary Uvicorn process remained
- no listener remained on the GM smoke port
- SQLite quick_check was ok
- CT202 had 25 application tables
- all inspected tables had zero rows
- jobs row count was 0
- workers row count was 0
- router_logs row count was 0
- router_resolution_steps row count was 0
- user_sessions row count was 0

The hash change was treated as lazy runtime schema/table initialization on the fresh CT202 DB. GM-R1B reran the same route smoke on the settled 25-table DB and confirmed the DB hash stayed unchanged.

## Runtime boundary

CT 202 is still not authoritative.

The laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority.

The laptop controller service remains the live controller.

## Not performed

- no route smoke rerun in record phase
- no persistent controller runtime activation
- no persistent Uvicorn process left running
- no systemd service creation
- no systemd enable
- no systemd start
- no laptop controller stop
- no data migration
- no data import
- no live laptop DB mutation
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no token or password recording
- no public API key recording
- no Phase 14J-AG apply wrapper rerun

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_gn_ct202_default_off_controller_systemd_unit_draft_no_enable_no_start_requires_explicit_approval
