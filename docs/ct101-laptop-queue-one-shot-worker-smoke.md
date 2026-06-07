# CT101 Laptop Queue One-Shot Worker Smoke — Stage 5E-10

## Purpose

Stage 5E-10 verifies CT101 can run a one-shot synthetic worker script against the laptop/controller queue API.

This stage uses synthetic jobs only.

## What this smoke does

1. Starts a temporary laptop queue API server.
2. Creates synthetic laptop queue jobs.
3. Runs the CT101 one-shot worker script once in success mode.
4. Runs the CT101 one-shot worker script once in failure mode.
5. Cleans up synthetic rows.

## What this smoke does not do

This smoke does not:

- modify the real CT101 worker service
- restart CT101 services
- change Docker Compose
- migrate production jobs
- change public UI behavior
- claim non-synthetic jobs

## Required CT101 script

The CT101 script is:

- /opt/ai-platform/ops/smoke/laptop_queue_one_shot_worker.py

## Safety

The CT101 script requires:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1

and refuses non-synthetic job IDs.
