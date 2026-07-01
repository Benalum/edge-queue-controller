# Stage 17K-Z-R10F — Verify Frontend Private Study Endpoint Cutover

This checkpoint verifies that the frontend no longer references private study persistence endpoints before backend route deletion.

## Result

The frontend should have zero references to private study persistence endpoints such as:

- `/api/study/decks`
- `/api/study/cards-lite`
- `/api/study/progress`
- `/api/study/review-summary-lite`
- `/api/study/sessions-lite`
- `/api/study/session-writeback-lite`
- `/api/study/deck-writeback-lite`
- `/api/study/card-writeback-lite`

## Why this matters

The user explicitly wants backend cleanup to be real endpoint removal, not a wrapper/bandage.

Before deleting backend routes, the frontend must not depend on those routes.

## Backend deletion policy

Next backend stage should remove private study persistence routes from source.

Do not merely wrap them with `403` or `410` handlers as the final solution.

Acceptable final result for removed private persistence endpoints:

- route source deleted
- public gateway mappings deleted
- frontend no longer calls them
- public requests return 404 because routes no longer exist

## Keep or review separately

Do not blindly remove all routes containing `study`.

Some routes may be AI/intent/Companion orchestration rather than private persistence. In particular, study intent parsing should be reviewed separately before deletion or rehoming.

## Generated evidence

- `frontend-private-endpoint-reference-scan.txt`
- `backend-private-endpoint-reference-scan.txt`
- `backend-removal-targets.txt`
- `summary.json`
