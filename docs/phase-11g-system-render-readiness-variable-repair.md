# Phase 11G System Render Readiness Variable Repair

Phase 11G repairs the stuck `/system` loading state after Phase 11E and Phase 11F.

## Baseline

Previous checkpoint:

- Phase: Phase 11F
- Commit: 2ab7fb2 fix: complete system loading render phase 11f
- Tag: controller-phase-11f-system-loading-completion-repair-2026-06-13

## Problem

The `/system` page is stuck on:

- Loading live platform status...
- Checking backend, frontend, queue, worker, and power automation status.

The verification output showed:

- The live `/api/system/status` endpoint returns HTTP 200 JSON.
- Served `app.js` includes the Phase 11F repair markers.
- `loadSystemStatus()` stores the live payload in `lastStatus`.
- `loadSystemStatus()` then sets `adminStatus = null`.
- The Phase 11E `renderSystemPage()` wrapper waits for `adminStatus`.

Because `adminStatus` is intentionally cleared, the wrapper never considers the page ready.

## Goal

Use the correct readiness variable for the public `/system` page.

The public System page should use `lastStatus`, because `loadSystemStatus()` stores the live `/system/status` payload there.

## Implementation

Phase 11G changes the Phase 11E `renderSystemPage()` wrapper:

- From checking `adminStatus`
- To checking `lastStatus`

It also changes the Phase 11F refresh helper readiness check:

- From `if (!adminStatus) return;`
- To `if (!lastStatus) return;`

## Safety posture

Allowed:

- Frontend JavaScript-only change.
- GET-only smoke checks.

Not allowed:

- No backend changes.
- No route handler changes.
- No CSS changes.
- No HTML changes.
- No auth changes.
- No logged-in/logged-out boundary changes.
- No router rollout.
- No backend router dry-run enablement.
- No frontend router POST traffic.
- No persistent rollout mutation routes.
- No service restarts.

## Done criteria

Phase 11G is done when:

- The Phase 11G marker exists exactly once.
- `renderSystemPage()` uses `lastStatus` for readiness.
- The old `const phase11eStatus = adminStatus || {};` pattern is gone.
- The Phase 11F helper checks `lastStatus`.
- JavaScript syntax check passes.
- `/system` returns HTTP 200.
- `/api/system/status` returns HTTP 200 JSON and remains fast.
- Router rollout remains parked.
- The commit and tag are pushed only after the smoke passes.
