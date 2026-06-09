# Stage 5G-27 — Live browser final regression

## Goal

Verify the complete live browser queued-chat path still works after managed worker service and System status updates.

## Path verified

Browser queued submit → laptop queued job → CT101 managed worker → Ollama → completed laptop job → browser-visible assistant reply.

## Also verified

The managed CT101 laptop queue worker remains visible through wrapper system status:

- state: online
- detail includes service active
- detail includes preflight ok
- detail includes paused no
- detail includes model gemma4:e4b
- detail includes queue counts

## Safety

This stage does not change runtime behavior.

This stage does not change worker concurrency.

This stage does not modify worker service files.

This stage does not expose secrets, tokens, prompts, or raw environment values.
