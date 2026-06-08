# Stage 5G-22 — Managed worker controls

## Goal

Add and verify health, pause, resume, restart, stop, start, and log controls for the managed CT101 laptop queue worker.

## What was proven

The CT101 managed worker service remained active.

The worker control command was installed at:

- /usr/local/bin/ai-platform-laptop-queue-workerctl

The worker loop is pause-aware through:

- /etc/ai-platform/laptop-queue-worker.paused

The following controls were verified:

- status
- pause
- resume
- logs

During pause, the worker loop wrote paused log lines and stopped polling.

After resume, the pause file was removed and the worker resumed bounded polling.

## Safety

This stage does not change worker concurrency.

This stage does not modify wrapper app.js queued submit.

This stage does not send client-provided user_id.

This stage keeps real-user job processing explicitly guarded by the existing worker environment.

## Next

Stage 5G-23 should add startup safety checks so the service refuses to run if required secrets, model configuration, laptop controller reachability, or queue flags are missing.
