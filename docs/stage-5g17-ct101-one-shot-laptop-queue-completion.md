# Stage 5G-17 — CT101 one-shot laptop queue completion

## Goal

Prove CT101 can claim and complete a laptop-owned queued job when explicitly pointed at the laptop queue.

## What was verified

A CT101 one-shot laptop queue worker was run with:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_BASE_URL=http://100.108.171.94:7070
- LAPTOP_QUEUE_WORKER_ID=ct101-stage5g17-one-shot
- LAPTOP_QUEUE_JOB_TYPE=ollama_chat

The worker claimed and completed a synthetic laptop app_jobs row.

## Important result

The successful one-shot output included:

- OK: claimed synthetic job
- PASS: completed synthetic job

The laptop database showed:

- status changed to complete
- assigned_worker_id was ct101-stage5g17-one-shot
- result_json was written

## Limitation

This stage does not enable persistent worker runtime.

This stage does not process real browser jobs.

This stage does not fix the browser UI timeout yet.

The next milestone should run a bounded real-user worker against a live browser-created queued job.

## Safety

- Uses synthetic-only worker mode.
- Does not enable real-user queue processing.
- Does not modify CT101 docker-compose.
- Does not modify the persistent CT101 worker loop.
