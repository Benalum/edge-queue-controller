# CT101 Bounded Synthetic Poller Smoke — Stage 5E-19

## Purpose

Stage 5E-19 verifies CT101 can run a smoke-only bounded synthetic laptop queue poller.

## What this smoke does

1. Starts a temporary laptop queue API server.
2. Creates two synthetic laptop jobs.
3. Ensures CT101 has the laptop queue token outside git.
4. Runs the CT101 bounded synthetic poller.
5. Verifies both synthetic jobs completed.
6. Verifies the worker returned idle.
7. Cleans up synthetic rows.

## CT101 script

- /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py

## Safety

The poller is explicitly bounded and synthetic-only.

It requires:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_POLL_MODE=bounded

## What this stage does not do

This stage does not:

- modify the production CT101 worker loop
- change Docker Compose
- start a persistent worker
- call real Ollama
- migrate production jobs
- claim non-synthetic jobs
- change user-facing behavior
