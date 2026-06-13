# Stage 8M Live Frontend Router Shadow-Read Network Audit

Stage 8M audits the live frontend assets after Stage 8L.

This is a docs/generated-report/smoke-only stage.

## Purpose

Stage 8L added a disabled Study router shadow-read observation call.

Stage 8M verifies the live frontend assets are served and still do not contain a router dry-run endpoint call.

## Safety

Stage 8M does not:

- modify runtime frontend code
- restart the live controller
- restart the wrapper UI
- enable the live router endpoint
- dispatch Study commands
- call models
- change Study behavior
- change Companion behavior

## Audit Method

The smoke loads live frontend assets from the local wrapper server:

- `/`
- `router_shadow_read_stub.js`
- the currently referenced `app.js`

Then it verifies:

- live `app.js` does not contain /api/router/dry-run

- `index.html` loads the disabled stub before `app.js`
- `app.js` contains the Stage 8L disabled observer marker
- `app.js` does not contain `/api/router/dry-run`
- the stub remains disabled with `ROUTER_SHADOW_READ_ENABLED = false`
- the isolated observer simulation skips without a router call
- platform health remains online
- queue remains clean

## Important Boundary

Stage 8M does not use browser DevTools. It is a local asset/network audit using curl plus static checks.

## Decision

Stage 8M proves the live-served frontend assets contain the disabled observation code while still containing no router dry-run endpoint call.

Stage 8N may add a deeper browser/manual verification checklist or begin planning a true feature flag that remains off by default.
