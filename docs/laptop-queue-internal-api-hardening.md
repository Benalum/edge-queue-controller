# Laptop Queue Internal API Hardening — Stage 5E-5

## Purpose

Stage 5E-5 hardens the internal laptop queue API token behavior before CT101 workers are allowed to connect.

This stage adds smoke coverage only.

## Covered behavior

The internal laptop queue API must enforce:

- missing X-Laptop-Queue-Token returns 401
- wrong X-Laptop-Queue-Token returns 403
- correct X-Laptop-Queue-Token allows access
- synthetic setup/cleanup still works with the correct token

## Why this matters

Before CT101 workers claim laptop-owned jobs, the laptop/controller queue endpoints must not be open to unauthenticated callers.

The queue token is the first guardrail before later worker identity and scoped credentials.

## Token source

The API supports the token from:

- LAPTOP_QUEUE_INTERNAL_TOKEN environment variable
- ~/.config/ai-platform-controller/internal-queue.env

The token value must stay outside git.

## What this stage does not do

This stage does not:

- connect CT101 workers
- expose user-facing queue UI
- migrate production jobs
- change production queue behavior
- rotate production secrets
- remove old CT101 job routes

## Next stage

Stage 5E-6 can prepare a real CT101 worker token file and read-only worker-connection plan.

Actual CT101 worker claim/complete behavior should still wait until a staged synthetic worker test is ready.
