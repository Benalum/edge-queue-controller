# Stage 5J-3 Compatibility-Code Audit — 2026-06-10

## Result

This stage audited compatibility code only. No source deletion was performed.

## Runtime status

- `edge-queue-public-gateway.service`: inactive
- `edge-queue-public-gateway.service`: disabled
- port `7071`: no listener

## Compatibility source retained intentionally

- `public_gateway.py`
- `cloudflare/edge-public-proxy/*`
- wrapper `/api/backend/*` bridge code
- controller `/public/study/*` aliases
- controller `/public/companion/*` aliases

## Why not delete yet

Study no longer needs the public gateway path, but Chat, Companion, and Calendar still need focused smoke tests before removing compatibility code.

The current safe decision is to keep compatibility source in the repository while ensuring it is not active in the direct Study path.

## Current active Study path

Browser -> laptop wrapper -> laptop controller `/api/study/*` -> laptop Study data

## Next cleanup sequence

1. Move Study into the shared wrapper layout.
2. Smoke-test Chat queued path and decide whether `/api/backend/*` bridge can be removed.
3. Smoke-test Companion direct controller routes.
4. Smoke-test Calendar route ownership.
5. Only then archive/remove inactive public gateway and Cloudflare Worker proxy source.
