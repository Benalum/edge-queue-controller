# Stage 16 FC-O45-E-AA-R5 — Chunked VM200 static realign

Date: 2026-06-24

## Result

Re-aligned the live VM200 Companion result visibility panel with the repo source using a chunked static deploy. This avoided the prior QGA argument-size failure and removed the bad live JavaScript probe pattern.

## Verification

- VM200 live app.js contains `X-APC-Companion-Result-Read-Only`.
- VM200 live app.js contains `fetch(probeConfig.url, probeConfig.options)`.
- VM200 live app.js does not contain `probeConfig.options ||`.
- Public root references `20260624fc045eaar5`.
- Public app.js HTTP 200.
- Signed-out `/api/me` remains HTTP 401.
- Public `/api/system/status` remains HTTP 200.

## Guardrails

No DB write, no job mutation, no backend restart, no worker/model/helper/runtime call, no scheduler/timer activation, no schema change, no CT/VM restart, no nginx/cloudflared mutation, and no storage mutation.
