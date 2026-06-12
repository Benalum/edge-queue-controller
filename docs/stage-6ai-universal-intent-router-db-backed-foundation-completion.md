# Stage 6AI Universal Intent Router DB-Backed Foundation Completion

Stage 6AI records completion of the DB-backed Universal Intent Router dry-run foundation.

This is a checkpoint/report stage.

This stage does not change runtime behavior.

This stage does not restart the controller.

This stage does not enable the router endpoint on the live controller.

This stage does not dispatch.

This stage does not call models.

## Completed foundation stages

### Stage 6AA

Added the Universal Intent Router SQLite schema module.

Created router foundation tables:

- `intent_definitions`
- `intent_routes`
- `global_phrase_bank`
- `user_phrase_bank`
- `user_language_preferences`
- `user_secondary_languages`
- `router_logs`
- `router_resolution_steps`
- `router_feedback`

### Stage 6AB

Wired the router SQLite schema into controller database initialization.

Also applied the schema to live SQLite without restarting the live controller.

### Stage 6AC

Added the Universal Intent Router seed data module.

Seed data includes:

- Study session intents
- Study card intents
- Companion chat intent
- Chat message intent
- Calendar draft intents
- Unknown unsupported fallback intent
- English Study phrases
- Spanish Study aliases

### Stage 6AD

Applied seed data to live SQLite without restarting the live controller.

Verified live counts:

- `intent_definitions >= 14`
- `intent_routes >= 14`
- `global_phrase_bank >= 34`

### Stage 6AE

Added read-only SQLite lookup helpers.

Verified exact phrase lookups:

- `next` -> `study.card.next`
- `skip` -> `study.card.skip`
- `show answer` -> `study.card.answer`
- `siguiente` -> `study.card.next`

### Stage 6AF

Connected read-only SQLite lookup observability to the existing disabled dry-run router response.

Preserved compatibility with legacy dry-run intent names such as:

- `study.next`
- `study.skip`
- `study.answer`
- `companion.chat`

Added DB-backed canonical lookup metadata such as:

- `router_lookup.sqlite_phrase_lookup.intent_key=study.card.next`

### Stage 6AG

Generated DB-backed dry-run router fixtures.

Locked in the new `router_lookup` response shape.

### Stage 6AH

Started a temporary second controller process on port `7071`.

Enabled the router endpoint only in that temporary process.

Verified DB-backed dry-run router HTTP response worked without touching the live systemd controller.

Verified the live controller on port `7070` still returned HTTP 404 for `/api/router/dry-run`.

## Current safe state

The platform now has a DB-backed Universal Intent Router foundation that can resolve seeded Study phrases in dry-run mode.

The live router endpoint remains disabled by default.

The live website behavior is unchanged.

The router does not dispatch actions.

The router does not call models.

The router does not mutate Study, Companion, Chat, Calendar, Profile, Admin, queue, worker, power, or auth state.

## Known compatibility boundary

The dry-run router response still uses legacy intent names in the main `intent.name` field.

Examples:

- `study.next`
- `study.skip`
- `study.answer`

The DB-backed canonical intent key is available in:

- `router_lookup.sqlite_phrase_lookup.intent_key`

Examples:

- `study.card.next`
- `study.card.skip`
- `study.card.answer`

A future stage can migrate the main dry-run response from legacy intent names to canonical DB-backed intent keys after fixtures and adapters are deliberately updated.

## Recommended next stages

Recommended safe next sequence:

1. Stage 6AJ: add a dry-run-only canonical intent shadow field, without replacing `intent.name`.
2. Stage 6AK: add Study adapter shadow comparison fixtures using DB-backed lookup metadata.
3. Stage 6AL: add user phrase-bank insert/list helpers, still no dispatch.
4. Stage 6AM: add language preference read/write helpers, still no dispatch.
5. Stage 6AN: add tiny model router classifier prompt harness for offline/manual testing only.
6. Stage 6AO: decide whether to migrate `intent.name` from legacy names to canonical DB-backed intent keys.
7. Stage 6AP: only after all dry-run tests pass, consider a gated Study-only router experiment for one non-destructive action.
