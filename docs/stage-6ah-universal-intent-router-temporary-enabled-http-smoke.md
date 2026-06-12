# Stage 6AH Universal Intent Router Temporary Enabled HTTP Smoke

Stage 6AH validates the DB-backed Universal Intent Router dry-run response over HTTP using a temporary second controller process.

This stage does not restart the live controller.

This stage does not change live frontend behavior.

This stage does not enable the router endpoint on the live controller.

This stage does not dispatch.

This stage does not call models.

## Why this stage exists

Stage 6AF added DB-backed phrase lookup observability to the dry-run router helper.

Stage 6AG recorded DB-backed fixture outputs.

Stage 6AH proves the same DB-backed dry-run response works through HTTP without touching the live `edge-queue-controller` systemd service.

## Temporary process

The smoke starts a temporary controller on:

- `http://127.0.0.1:7071`

Only the temporary process gets:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`
- `EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3`

The live controller on port `7070` remains unchanged.

## Expected HTTP behavior

The temporary controller should return HTTP 200 for:

- `POST /api/router/dry-run`

The response should include:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `router_lookup.stage=6AF`
- `router_lookup.sqlite_phrase_lookup.intent_key=study.card.next` for `next`

The live controller should still return HTTP 404 for:

- `POST http://127.0.0.1:7070/api/router/dry-run`

## Stage boundary

Stage 6AH does not wire Study input into the router.

Stage 6AH does not wire Companion input into the router.

Stage 6AH does not wire Chat input into the router.

Stage 6AH does not wire Calendar input into the router.

Stage 6AH does not restart systemd services.
