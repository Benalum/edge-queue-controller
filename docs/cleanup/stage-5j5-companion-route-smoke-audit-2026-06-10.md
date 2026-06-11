# Stage 5J-5 Companion Route Smoke Audit — 2026-06-10

## Purpose

Audit whether Companion routes are using the laptop wrapper/controller path instead of the inactive public gateway.

## Result

This stage is audit-only. No compatibility code is removed.

## Things to decide from terminal output

- Does `/companion` load through the laptop wrapper?
- Do `/api/companion/context`, `/api/companion/chat`, and `/api/companion/study/grade` return controlled auth/validation responses instead of HTTP 502?
- Does the wrapper route `/api/companion/*` to the laptop controller?
- Are any active browser files still calling `/public/companion/*`, `7071`, or the public gateway?

## Safe cleanup rule

Do not remove `/public/companion/*`, `public_gateway.py`, or Cloudflare Worker proxy source until Companion browser behavior is verified while logged in.

## Observed result

- `/companion` shell returned HTTP 200 from the laptop wrapper.
- `/api/companion/context` returned HTTP 401 Missing bearer token, not HTTP 502.
- `/api/companion/chat` returned HTTP 401 Missing bearer token, not HTTP 502.
- `/api/companion/study/grade` returned HTTP 401 Missing bearer token, not HTTP 502.
- `edge-queue-public-gateway.service` remains inactive and disabled.
- Port `7071` has no listener.

## Decision

Keep `/public/companion/*`, `public_gateway.py`, and Cloudflare Worker proxy source for now.

Reason: unauthenticated route smoke proves the direct laptop route is controlled, but logged-in browser Companion behavior still needs to be verified before deleting compatibility code.
