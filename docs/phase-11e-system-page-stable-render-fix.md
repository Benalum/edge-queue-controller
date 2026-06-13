# Phase 11E System Page Stable Render Fix

Phase 11E fixes the user-visible `/system` double-render/flicker found after Phase 11C and inspected in Phase 11D.

## Baseline

Previous checkpoint:

- Phase: Phase 11D
- Commit: e0d2f8e docs: inspect system page double render phase 11d
- Tag: controller-phase-11d-system-page-double-render-inspection-2026-06-13
- Result: PASS

## User-visible issue

The `/system` page appears to render two different versions:

First render:

- Study API
- Companion API
- Profile API
- Calendar Integrations
- Images API

Second render shortly after:

- Backend API
- Frontend Wrapper
- Queue
- Workers
- CT101 Laptop Queue Worker
- Power Automation

This makes the page feel like it loads twice.

## Goal

Make `/system` use one stable render path:

1. Show a clear loading state while live system status is unavailable.
2. Show the existing live system status layout after status loads.
3. Do not show the older static API catalog as a temporary placeholder.

## Implementation

Phase 11E keeps the original `renderSystemPage()` implementation by renaming it to `phase11eRenderSystemPageOriginal()`.

A new wrapper `renderSystemPage()` returns a stable loading card until the live status payload is present, then delegates to the original render implementation.

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

Phase 11E is done when:

- The Phase 11E marker exists exactly once in `frontend/wrapper-ui/app.js`.
- The original System render function is preserved as `phase11eRenderSystemPageOriginal()`.
- The new `renderSystemPage()` wrapper exists.
- No Python/backend files changed.
- No CSS/HTML files changed.
- `/system` returns HTTP 200.
- Static assets return HTTP 200.
- `/api/system/status` returns HTTP 200 JSON and remains fast.
- Router rollout remains parked.
- The commit and tag are pushed only after the smoke passes.
