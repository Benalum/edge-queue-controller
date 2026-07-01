# Stage 17K-Z-R10J-R3 — Live Deploy Private Study Route Removal

This stage completed the live deploy after R10J-R2 exposed a smoke-script bug.

## Why R10J-R3 was needed

R10J-R2 reached deploy, then the smoke script rolled back because `grep` returned exit code `1` when it found zero `/api/study` references in `study-store.js`.

Zero references was the desired result.

R10J-R3 replaced those smoke checks with Python string counts.

## Live changes

CT203 backend:

- `edge_controller.py` deployed.
- `public_gateway.py` deployed.
- backend service restarted.

VM200 frontend:

- `index.html` deployed with the new `study-store.js` cache-bust version.
- `privatepages/study-store.js` deployed.
- `privatepages/local-save-store.js` deployed.

## Removal proof

The installed CT203 backend source was checked after deploy.

Only two study routes remain:

- `/public/study/intent/parse`
- `/api/study/intent/parse`

Private study persistence routes are absent from installed source.

## HTTP status note

Some signed-out removed `/api/study/*` requests may return `401` if authentication is enforced before final route resolution. The source-level proof is the installed CT203 route catalog: private persistence route decorators are absent.

## No database deletion

No DB write occurred.

No DB tables were dropped.
