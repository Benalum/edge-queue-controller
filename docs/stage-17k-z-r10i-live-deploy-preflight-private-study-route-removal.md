# Stage 17K-Z-R10I — Live Deploy Preflight for Private Study Route Removal

This stage is read-only preflight before deploying the private study route removal.

## Scope

No deploy occurred.

No live backend or frontend mutation occurred.

## Purpose

Verify that source is ready and live access paths are understood before deploying:

- frontend no longer references private study persistence endpoints
- backend source contains only study intent parse routes
- public health endpoints are reachable
- signup remains closed
- SSH access posture is known
- current live private study endpoint posture is recorded before removal reaches production

## Expected later deploy result

After deployment, removed private study persistence endpoints should return 404 because the routes no longer exist.

This must not be implemented as wrapper guards.

## Kept for separate review

- `/public/study/intent/parse`
- `/api/study/intent/parse`
