# Stage 16 FC-O45-E-AA-R11 — Result panel exact auth helper

Date: 2026-06-24

## Result

Updated the Companion result visibility panel to use the exact bearer-token lookup and `credentials: "include"` behavior used by the passing Companion auth validation test.

## Verification

- Public `/api/system/status`: HTTP 200.
- Public signed-out `/api/me`: HTTP 401.
- Public root references `20260624fc045eaar11`.
- Public app.js includes `FC-O45-E-AA-R11 read completed Companion result only`.
- Public app.js includes `credentials: "include"`.

## Guardrails

No DB write, no job mutation, no backend patch, no backend restart, no worker/model/helper/runtime call, no scheduler/timer activation, no schema change, no CT/VM restart, no nginx/cloudflared mutation, and no storage mutation.
