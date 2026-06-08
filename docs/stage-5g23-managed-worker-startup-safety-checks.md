# Stage 5G-23 — Managed worker startup safety checks

## Goal

Add startup safety checks to the managed CT101 laptop queue worker service.

## What this stage verifies

The CT101 managed worker now runs a preflight before service startup.

The preflight validates:

- queue enabled flag
- synthetic-only disabled for real-user processing
- real-user jobs explicitly enabled
- max jobs per run remains 1
- laptop queue base URL exists
- token file exists and is non-empty
- worker id exists
- Ollama URL exists
- model fallback exists
- laptop controller health is reachable
- Ollama tags endpoint is reachable

## Safety

The service refuses to start if required queue configuration or connectivity is missing.

This stage keeps worker concurrency at 1.

This stage does not modify wrapper app.js queued submit.

This stage does not send client-provided user_id.

## Next

Stage 5G-24 should add a dashboard/status surface for the managed worker so the website can show worker health and pause state.
