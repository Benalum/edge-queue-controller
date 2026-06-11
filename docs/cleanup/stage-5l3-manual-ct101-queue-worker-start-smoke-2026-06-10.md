# Stage 5L-3 Manual CT101 Queue Worker Start Smoke — 2026-06-10

## Purpose

Manually start the CT101 laptop queue worker service without enabling it permanently.

## Expected safe behavior

- ai-platform-laptop-queue-worker.service starts cleanly.
- Worker either remains active or performs bounded idle polling cleanly.
- No queued jobs are required for this smoke.
- Do not enable the service yet.

## Safety boundary

This stage changes runtime service state only.
No source code changes were made.
Permanent enablement is deferred until a real queued-chat smoke passes.
