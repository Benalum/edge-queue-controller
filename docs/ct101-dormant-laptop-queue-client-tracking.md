# CT101 Dormant Laptop Queue Client Tracking — Stage 5E-11

## Purpose

Stage 5E-11 tracks the CT101 dormant laptop queue client module from the controller repo.

## CT101 module

The CT101 module is:

- backend/app/worker/laptop_queue_client.py

The CT101 smoke is:

- ops/smoke/check-laptop-queue-client-dormant.sh

## Safety

The client is not wired into the production CT101 worker loop yet.

It requires explicit environment flags before active use.

Synthetic-only mode refuses non-synthetic job IDs.

## What this stage does not do

This stage does not:

- change production worker behavior
- restart CT101 services
- change Docker Compose
- migrate production jobs
- claim real jobs
- change public UI behavior

## Next stage

Stage 5E-12 can add a controller smoke that runs the dormant client against synthetic laptop jobs, without touching the real CT101 worker service.
