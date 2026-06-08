# Stage 5G-20 — Safe persistent CT101 laptop queue worker runtime

## Goal

Verify a safe CT101 laptop-queue worker runtime can automatically process live browser-created queued chat jobs.

## What was proven

A temporary CT101 background worker loop was started.

A browser queued chat message created a laptop-owned real-user app_jobs row.

The CT101 worker automatically claimed the job.

The job moved from running to complete.

The completed job used:

- worker_id: ct101-stage5g20-persistent-browser
- requested_model: gemma4:e4b
- result_json reply: OK

## Runtime files on CT101

- /tmp/stage5g20-ct101-laptop-queue-worker.pid
- /tmp/stage5g20-ct101-laptop-queue-worker.log

## Safety

This stage does not modify CT101 docker-compose.

This stage does not install a permanent systemd service.

This stage does not increase concurrency above 1.

This stage does not enable wrapper app.js queued submit.

Rollback is stopping the single temporary CT101 worker process.

## Next

Stage 5G-21 should convert the temporary worker runtime into a managed service with restart behavior, logs, and pause/resume controls.
