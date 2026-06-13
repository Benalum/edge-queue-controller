# Phase 11F System Loading Completion Repair

Phase 11F repairs the Phase 11E System page stable-render fix.

## Problem

Phase 11E stopped `/system` from flashing the old static API catalog, but the page can remain stuck on:

- Loading live platform status...
- Checking backend, frontend, queue, worker, and power automation status.

This happens because live status loads asynchronously, but the visible `/system` page is not refreshed after `loadSystemStatus()` completes.

## Goal

Keep the stable loading state, then replace it with the live System status layout as soon as live status is available.

## Implementation

Phase 11F:

- Gives the System loading section a stable DOM id.
- Adds a small frontend helper that replaces the loading section with the preserved original System renderer output after `adminStatus` is available.
- Calls that helper after `loadSystemStatus()` refreshes the drawer/status data.
- Keeps the original Phase 11E preserved renderer.
- Keeps `/system` frontend-only.

## Safety posture

Allowed:

- Frontend JavaScript-only change.
- GET-only smoke checks.
- No service restart.

Not allowed:

- No backend changes.
- No route handler changes.
- No auth changes.
- No logged-in/logged-out boundary changes.
- No router rollout.
- No backend router dry-run enablement.
- No frontend router POST traffic.
- No persistent rollout mutation routes.
- No service restarts.

## Done criteria

Phase 11F is done when:

- The Phase 11F marker exists exactly once.
- The System loading section has a stable DOM id.
- `loadSystemStatus()` calls the Phase 11F refresh helper.
- JavaScript syntax check passes.
- `/system` returns HTTP 200.
- Static assets return HTTP 200.
- `/api/system/status` returns HTTP 200 JSON and remains fast.
- Router rollout remains parked.
- The commit and tag are pushed only after the smoke passes.
