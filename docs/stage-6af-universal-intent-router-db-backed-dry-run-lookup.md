# Stage 6AF Universal Intent Router DB-Backed Dry-Run Lookup

Stage 6AF adds SQLite phrase lookup observability to the disabled Universal Intent Router dry-run response.

This stage does not change live page behavior.

This stage does not wire router dispatch.

This stage does not call models.

This stage does not enable the router endpoint by default.

## Why this stage exists

Stage 6AA added router SQLite schema.

Stage 6AB wired router schema creation into controller SQLite initialization.

Stage 6AC added router seed data.

Stage 6AD applied seed data to live SQLite.

Stage 6AE added read-only SQLite lookup helpers.

Stage 6AF connects the read-only lookup helper to the existing dry-run router response as observability only.

## What changes

The dry-run router response now includes:

- `router_lookup.stage`
- `router_lookup.sqlite_phrase_lookup`
- a `decision_trace` step named `sqlite_phrase_lookup`

The existing final trace step remains `rule_result`.

## Safety boundary

The router still returns:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `eligible_for_dispatch=false`

The router endpoint remains disabled by default.

This stage does not route Study input through the router.

This stage does not route Companion input through the router.

This stage does not route Chat input through the router.

This stage does not route Calendar input through the router.

This stage does not restart the controller.

## Compatibility boundary

Stage 6AF does not replace legacy dry-run intent names yet.

For compatibility, the existing dry-run rules still produce legacy names such as:

- `study.next`
- `study.skip`
- `study.answer`
- `companion.chat`

The new DB-backed lookup exposes canonical seeded intent keys such as:

- `study.card.next`
- `study.card.skip`
- `study.card.answer`

A later explicit stage can migrate the dry-run response to canonical DB-backed intent names after fixture and adapter compatibility is updated.

## Expected lookup examples

When the dry-run helper receives Study-context input:

- `next` should expose `study.card.next` in `router_lookup.sqlite_phrase_lookup.intent_key`
- `skip` should expose `study.card.skip`
- `show answer` should expose `study.card.answer`
- `siguiente` should expose `study.card.next`

## Stage 6AF acceptance criteria

Stage 6AF is complete when:

- `edge_intent_router.py` compiles.
- Existing Stage 6N response schema smoke still passes.
- Existing Stage 6AE lookup helper smoke still passes.
- Direct dry-run helper calls expose DB-backed lookup metadata.
- The final decision trace step remains `rule_result`.
- No dispatch is performed.
- No model call is required.
- The endpoint remains disabled by default.
