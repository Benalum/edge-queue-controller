# Stage 5G-21 — Managed CT101 laptop queue worker service

## Goal

Convert the temporary Stage 5G-20 CT101 laptop queue worker into a managed systemd service.

## What was proven

A systemd service was installed on CT101:

- ai-platform-laptop-queue-worker.service

The service runs the CT101 laptop queue worker loop.

A live browser queued chat message was created through the wrapper.

The managed CT101 worker automatically claimed and completed the laptop queue job.

The completed job used:

- worker_id: ct101-stage5g21-managed-browser
- requested_model: gemma4:e4b
- status: complete

## Safety

This stage keeps concurrency at 1.

This stage requires real-user queue processing to be explicitly enabled.

This stage does not modify wrapper app.js queued submit.

This stage does not send client-provided user_id.

## Rollback

Stop the service on CT101:

systemctl stop ai-platform-laptop-queue-worker.service

## Next

Stage 5G-22 should add health checks, pause/resume controls, and safe startup behavior.
