# CT101 to Laptop Queue Read-Only Connectivity — Stage 5E-7

## Purpose

Stage 5E-7 proves CT101 can authenticate to the laptop/controller internal queue API using the laptop queue token.

This stage is read-only from the queue perspective.

## What this stage does

The smoke test:

1. Reads the laptop queue token from the laptop token file.
2. Copies the token to CT101 outside git.
3. Starts a temporary laptop Uvicorn server bound to 0.0.0.0.
4. Verifies the laptop endpoint is reachable locally.
5. From CT101, calls the laptop read-only summary endpoint.
6. Verifies the response contains ok=true.

## CT101 token location

The CT101 token file is stored outside git:

- /opt/ai-platform/.secrets/laptop-queue.env

It contains:

- LAPTOP_QUEUE_INTERNAL_TOKEN

The file must be chmod 600.

## Read-only endpoint tested

The tested endpoint is:

- GET /internal/laptop-queue/summary

## What this stage does not do

This stage does not:

- claim laptop jobs from CT101
- complete laptop jobs from CT101
- modify CT101 worker code
- modify CT101 Docker Compose
- migrate production jobs
- change public UI behavior
- change power automation
- remove CT101 job routes

## Why this matters

Before CT101 workers can safely claim laptop-owned jobs, CT101 must first prove it can reach the laptop/controller queue API with authentication.

This keeps the next worker integration stage smaller and safer.

## Next stage

Stage 5E-8 can add a CT101 synthetic claim/complete smoke.

That future smoke should still use synthetic jobs only and should not change production worker behavior.
