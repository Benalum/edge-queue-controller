# Stage 5O-7 Manual Browser UI Checklist — 2026-06-11

## Result

Manual browser UI checklist stage created.

## Checkpoint before checklist

- Commit: `90c0e54`
- Tag: `controller-stage-5o6-logged-in-core-feature-smoke-2026-06-11`

## Pages to verify manually

- `/`
- `/chat`
- `/companion`
- `/study`
- `/calendar`
- `/profile`
- `/admin`

## Expected behavior

- Public and private routes load quickly.
- Login stays stable.
- Study deck is visible.
- Companion queued response works.
- Calendar remains Google/Apple provider-only direction.
- No local calendar database/API should be added.
- Backend health remains responsive.
- Wrapper public status remains responsive.

## Notes

Cloudflare beacon or browser tracking-protection messages are not app failures.

Real failures to watch for:

- App route 404s
- Auth loops
- 500/502/504 responses
- Uncaught JavaScript errors
- Queued Companion jobs stuck forever
