# Stage 6I Universal Intent Router Command Aliases

Stage 6I expands deterministic dry-run command aliases for the Universal Intent Router helper.

The endpoint remains disabled by default.

This stage does not wire the router into any app page.

## Purpose

Users will not always type exact button labels.

The dry-run helper should recognize common wording variations before any real page integration begins.

## Added alias coverage

Study next aliases:

- n
- next card
- go on

Study skip aliases:

- dont know
- not sure

Study hint aliases:

- show hint
- give me a hint

Spanish examples:

- omitir
- ayuda
- próximo
- proximo

## Safety expectations

Every alias fixture must prove:

- dry_run=true
- dispatch_performed=false
- model_call_required=false
- allowed_to_dispatch=false

## Stage boundary

Stage 6I only updates disabled dry-run helper classification and smoke fixtures.

Stage 6I does not enable dispatch.

Stage 6I does not call a model.

Stage 6I does not modify frontend wiring.
