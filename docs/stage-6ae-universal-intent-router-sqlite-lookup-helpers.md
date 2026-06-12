# Stage 6AE Universal Intent Router SQLite Lookup Helpers

Stage 6AE adds read-only SQLite lookup helpers for the Universal Intent Router.

This stage does not change runtime behavior.

This stage does not wire router dispatch.

This stage does not call models.

This stage does not modify frontend behavior.

## Why this stage exists

Stage 6AA added the router SQLite schema module.

Stage 6AB wired the schema into controller SQLite initialization.

Stage 6AC added router seed data.

Stage 6AD applied the seed data to live SQLite without restart.

Stage 6AE adds read-only lookup helpers so the router can resolve exact phrase-bank entries from SQLite.

## New module

`edge_router_lookup.py`

The module provides:

- `normalize_router_phrase(text)`
- `lookup_global_phrase(conn, input_text, language_code, context_domain)`
- `lookup_router_exact_phrase(conn, input_text, language_code, context_domain)`

## Lookup examples

Expected exact lookups include:

- `next` -> `study.card.next`
- `skip` -> `study.card.skip`
- `show answer` -> `study.card.answer`
- `correct` -> `study.card.correct`
- `wrong` -> `study.card.incorrect`
- `siguiente` -> `study.card.next`
- `omitir` -> `study.card.skip`
- `mostrar respuesta` -> `study.card.answer`

## Safety boundary

The lookup helper only reads from SQLite.

It does not execute Study actions.

It does not execute Companion actions.

It does not execute Chat actions.

It does not execute Calendar actions.

It does not call an LLM.

It does not enable the router endpoint.

It always reports:

- `dispatch_performed=false`
- `model_call_required=false`

## Future stage

A later stage can connect this read-only lookup helper into the disabled dry-run router response path.

That future stage must still preserve:

- no dispatch
- no model calls
- dry-run endpoint disabled by default
