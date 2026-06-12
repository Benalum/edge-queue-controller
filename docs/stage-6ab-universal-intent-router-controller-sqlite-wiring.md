# Stage 6AB Universal Intent Router Controller SQLite Wiring

Stage 6AB wires the Universal Intent Router persistent SQLite schema into the controller database initialization path.

This stage is additive.

This stage creates router tables when the controller initializes the SQLite database.

This stage does not wire the router into Study, Companion, Chat, Calendar, Profile, Admin, queue, worker, frontend behavior, or power automation behavior.

This stage does not enable router dispatch.

This stage does not enable model calls.

## Why this stage exists

Stage 6AA added the standalone router schema module.

Stage 6AB connects that module to the controller database initialization path so the router foundation tables exist in the same SQLite database that currently holds app users, sessions, Study data, queue state, power state, credits, support, and related controller data.

## Files changed

- `edge_controller.py`
- `docs/stage-6ab-universal-intent-router-controller-sqlite-wiring.md`
- `ops/smoke/check-stage-6ab-universal-intent-router-controller-sqlite-wiring.sh`

## Runtime safety boundary

This stage only creates tables and indexes.

It does not route any live user input.

It does not change existing Study commands.

It does not change Companion behavior.

It does not change Chat behavior.

It does not change Calendar behavior.

It does not change auth behavior.

It does not change power automation behavior.

It does not change queue or worker behavior.

## Router tables expected after controller initialization

- `intent_definitions`
- `intent_routes`
- `global_phrase_bank`
- `user_phrase_bank`
- `user_language_preferences`
- `user_secondary_languages`
- `router_logs`
- `router_resolution_steps`
- `router_feedback`

## Verification strategy

The smoke test verifies:

1. `edge_controller.py` imports the router schema initializer.
2. `edge_controller.py` calls `init_router_foundation_schema(conn)`.
3. `edge_controller.py` and `edge_router_schema.py` compile.
4. A temporary SQLite DB can be initialized through `edge_controller.init_db()`.
5. The temporary DB receives the router foundation tables.
6. The dry-run router endpoint remains disabled by default in code.

## Live apply strategy

After commit, the live database should be backed up before restarting the controller.

Then the controller should restart and create the router tables automatically.

Live verification should confirm:

- controller health is good
- router tables exist in `edge_queue.sqlite3`
- `/api/router/dry-run` remains disabled by default
- no dispatch is enabled
