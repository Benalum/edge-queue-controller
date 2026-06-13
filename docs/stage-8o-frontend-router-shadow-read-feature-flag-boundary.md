# Stage 8O Frontend Router Shadow-Read Feature Flag Boundary

Stage 8O adds a frontend feature-flag boundary for future router shadow-read work.

## Purpose

Stage 8N decided not to enable real router traffic yet.

Stage 8O adds a source-level feature-flag boundary while keeping the feature off by default.

## Files Changed

- `frontend/wrapper-ui/router_shadow_read_stub.js`

## Safety

Stage 8O does not:

- add a router endpoint URL to frontend code
- add `/api/router/dry-run` to `app.js`
- enable router traffic
- enable dispatch
- enable model calls
- change Study behavior
- change Companion behavior
- restart the live controller

## Feature Flag State

The feature flag remains off by default:

- `ROUTER_SHADOW_READ_ENABLED = false`
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`
- `isRouterShadowReadFeatureEnabled() = false`

## Runtime Behavior

While disabled, `routerShadowRead()` must:

- skip
- not call the API function
- not dispatch
- not call models
- return `reason = router_shadow_read_disabled`

## Decision

Stage 8O creates the feature-flag boundary only.

Stage 8P may plan a backend/live dry-run feature flag, but real router traffic should remain off until a separate go decision.
