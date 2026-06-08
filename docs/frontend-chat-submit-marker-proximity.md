# Frontend Chat Submit Marker Proximity — Stage 5F-44

## Purpose

Stage 5F-44 proves the queued-chat submit insertion marker is near the real frontend submit path.

This stage is static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## What is verified

The smoke verifies:

- Stage 5F-43 marker exists in app.js
- the marker is close to a submit listener or submit handler anchor
- the queued submit decision helper is still not called
- the queued send helper is still not called by submit
- the queued status poller is still not called
- the queued placeholder helper is still not called
- decisionWired remains false
- wiredToSubmit remains false
- pollerWired remains false
- placeholderWired remains false

## Safety

This stage does not modify app.js.

This stage does not submit queued jobs.

This stage does not start polling.

This stage does not render placeholders.

This stage does not call CT101.

This stage does not call Ollama.

The frontend must not send client-provided identity fields.

The frontend must not send synthetic-user headers.

## Required future behavior

A later wiring stage must still prove:

- flag off keeps legacy submit path
- flag on only calls queued decision once
- flag on only calls queued send once
- flag on only starts one polling loop per job
- rollback returns to legacy path
- duplicate messages are not rendered

## Recommended Stage 5F-45

Stage 5F-45 should add a disabled-by-default real submit decision dry-run helper that can be tested without changing the live submit flow.

Production queued chat should remain disabled unless explicitly enabled.
