# Stage 17K-Z-R10G-R3 — Remove Private Study Route Metadata Leftovers

This stage completes real source removal of private study server persistence routes.

## What happened

R10G removed route handlers and public gateway mappings, but verification found stale endpoint strings still present in backend metadata dictionaries.

R10G-R3 removed those stale metadata references as well.

## User direction

Backend cleanup must be actual removal, not wrapper guards.

## Final source policy

Private study data is browser-local only.

Removed from backend source:

- private study route decorators
- private study route handler functions
- public gateway private study mappings
- stale metadata references to private study persistence routes

Kept for separate review:

- `/public/study/intent/parse`
- `/api/study/intent/parse`

Those are not private persistence endpoints and may belong to AI/Companion orchestration.

## Safety

No deploy was performed.

No live backend was changed.

No DB tables were dropped.

After a future deploy, deleted private persistence endpoints should return 404 because they no longer exist in source.
