# CT101 Real-User Execution Guard Tracking — Stage 5F-22

## Purpose

Stage 5F-22 tracks the CT101 dormant real-user execution guard from the controller repo.

## CT101 guard

CT101 now has a dormant guard requiring:

- LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1

before non-synthetic laptop queue jobs are allowed.

## Safety

Synthetic-only smokes remain unchanged.

Real-user jobs are still not processed by persistent workers.

Controller real-user queued chat remains disabled by default.

## CT101 files

- backend/app/worker/laptop_queue_client.py
- docs/laptop-queue-real-user-execution-guard.md
- ops/smoke/check-laptop-queue-real-user-execution-guard.sh

## CT101 tag

- ai-platform-stage-5f22-real-user-execution-guard-2026-06-07

## Next stage

Stage 5F-23 should add a bounded one-shot real-user route-to-CT101 smoke using synthetic test users and cleanup rows.
