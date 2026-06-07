# CT101 Bounded Real-User Poller Tracking — Stage 5F-23

## Purpose

Stage 5F-23 tracks the CT101 bounded real-user poller guard from the controller repo.

## CT101 behavior

CT101 bounded poller now supports explicit real-user bounded mode only when:

- LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1

Synthetic-only mode remains supported.

## Safety

Persistent workers are still not enabled.

Real-user queued chat remains disabled by default.

The next smoke should use synthetic test users and cleanup rows.

## CT101 files

- ops/smoke/laptop_queue_bounded_synthetic_poller.py
- docs/laptop-queue-bounded-real-user-poller.md
- ops/smoke/check-laptop-queue-bounded-real-user-poller-static.sh

## CT101 tag

- ai-platform-stage-5f23-bounded-real-user-poller-guard-2026-06-07

## Next stage

Stage 5F-24 should add a controller-side real-user route-to-CT101 bounded lifecycle smoke.
