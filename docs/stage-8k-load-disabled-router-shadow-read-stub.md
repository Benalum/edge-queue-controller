# Stage 8K Load Disabled Router Shadow-Read Stub

Stage 8K loads the disabled frontend router shadow-read stub in the browser page while keeping it inactive.

## Files Changed

- `frontend/wrapper-ui/router_shadow_read_stub.js`
- `frontend/wrapper-ui/index.html`

## Purpose

Stage 8I created a disabled-by-default stub.

Stage 8J proved the stub can consume safe decision contract fixtures.

Stage 8K makes the stub available to the browser as a passive namespace:

- `window.EdgeRouterShadowRead`

## Safety

Stage 8K does not:

- enable router shadow-read
- modify `frontend/wrapper-ui/app.js`
- add `/api/router/dry-run` calls to `app.js`
- enable the live router endpoint
- restart the live controller
- dispatch Study commands
- call models
- change Study behavior
- change Companion behavior

## Disabled State

The loaded stub remains disabled:

- `ROUTER_SHADOW_READ_ENABLED = false`

When called, `routerShadowRead()` still returns:

- `skipped = true`
- `reason = router_shadow_read_disabled`
- `dispatch_performed = false`
- `allowed_to_dispatch = false`
- `would_dispatch = false`

## Browser Namespace

The stub exposes:

- `window.EdgeRouterShadowRead.buildRouterShadowReadPayload`
- `window.EdgeRouterShadowRead.extractRouterDecisionContract`
- `window.EdgeRouterShadowRead.isRouterDecisionShadowSafe`
- `window.EdgeRouterShadowRead.routerShadowRead`

No function runs automatically on page load.

## Decision

Stage 8K makes the disabled helper browser-loadable without wiring it into Study or Companion behavior.

Stage 8L may add a disabled no-op observation call in one controlled frontend location only after proving it cannot call the router while disabled.
