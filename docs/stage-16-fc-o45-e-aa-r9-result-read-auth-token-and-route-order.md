# Stage 16 FC-O45-E-AA-R9 — Result read auth token and route order fix

Date: 2026-06-24

## Result

Fixed the Companion result visibility path by:

1. Moving the read-only result mode before the auth-validation early return inside the actual Companion common route.
2. Updating the result panel to add the same Bearer-token style auth behavior used by the passing Companion auth test.

## Endpoint mode

`POST /api/companion/chat`

Header:

`X-APC-Companion-Result-Read-Only: FC-O45-E-AA`

Body:

`{"job_id":124,"message":"FC-O45-E-AA-R9 read completed Companion result only"}`

The mode is read-only and returns existing job/result data only.

## Guardrails

No DB write, no job mutation, no worker/model/helper/runtime call, no scheduler/timer activation, no schema change, no CT/VM restart, no nginx/cloudflared mutation, and no storage mutation.
