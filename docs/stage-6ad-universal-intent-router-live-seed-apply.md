# Stage 6AD Universal Intent Router Live Seed Apply

Stage 6AD applied the Universal Intent Router seed data to the live SQLite database without restarting the controller.

This stage did not change frontend behavior.

This stage did not wire router dispatch.

This stage did not enable model calls.

This stage did not restart the controller.

## Why this stage exists

Stage 6AA added the router SQLite schema module.

Stage 6AB wired router schema creation into controller SQLite initialization and also applied the schema directly to the live SQLite database.

Stage 6AC added the router seed data module.

Stage 6AD applied that seed data to the live SQLite database without interrupting the browser or restarting the controller.

## Live seed result

The live SQLite database now contains initial router configuration data.

Expected minimum counts:

- `intent_definitions`: 14
- `intent_routes`: 14
- `global_phrase_bank`: 34

## Seed groups applied

Intent definitions include:

- Study session intents
- Study card intents
- Companion chat intent
- Chat message intent
- Calendar event draft intent
- Calendar reminder draft intent
- Unknown unsupported fallback intent

Global phrase bank entries include:

- English Study navigation phrases
- English Study answer phrases
- English Study scoring phrases
- Spanish Study aliases

## Safety verification

The controller stayed active.

The controller health endpoint returned HTTP 200.

The Universal Intent Router dry-run endpoint remained disabled by default and returned HTTP 404.

No router dispatch was enabled.

No model call was enabled.

No restart was required.

## Stage boundary

Stage 6AD only records and verifies live seed data.

It does not route Study input through the router.

It does not route Companion input through the router.

It does not route Chat input through the router.

It does not route Calendar input through the router.

It does not enable agents, tools, automations, or model routing.

## Next stage

The next safe stage should add read-only router lookup helpers that can resolve exact direct actions and phrase bank entries from SQLite without dispatching.

Recommended next stage:

Stage 6AE Universal Intent Router SQLite Lookup Helpers
