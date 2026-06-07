# CT101 Dormant Client One-Shot Smoke — Stage 5E-12

## Purpose

Stage 5E-12 verifies CT101 can use the reusable dormant laptop queue client against synthetic laptop queue jobs.

## What this smoke does

1. Starts a temporary laptop queue API server.
2. Creates synthetic laptop jobs.
3. Runs CT101 dormant client one-shot success mode.
4. Runs CT101 dormant client one-shot failure mode.
5. Cleans up synthetic rows.

## CT101 scripts used

- backend/app/worker/laptop_queue_client.py
- ops/smoke/laptop_queue_client_one_shot.py
- ops/smoke/check-laptop-queue-client-one-shot.sh

## What this stage does not do

This stage does not:

- modify the production CT101 worker loop
- restart CT101 services
- change Docker Compose
- migrate production jobs
- claim non-synthetic jobs
- change user-facing behavior

## Safety

The CT101 one-shot runner must use:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1

and the dormant client refuses non-synthetic jobs in synthetic-only mode.
