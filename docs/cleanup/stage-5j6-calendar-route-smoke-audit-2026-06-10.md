# Stage 5J-6 Calendar Route Smoke Audit — 2026-06-10

## Purpose

Audit whether Calendar routes are currently served by the laptop wrapper/controller and whether any old public-gateway or CT101 route ownership remains active.

## Result

This stage is audit-only. No compatibility code is removed.

## Things to decide from terminal output

- Does `/calendar` load through the laptop wrapper?
- Do `/api/calendar` and `/api/calendar/events` return controlled responses instead of HTTP 502?
- Does the wrapper route `/api/calendar/*` to the laptop controller?
- Is Calendar currently only a planning/integration page rather than a finished backend API?

## Safe cleanup rule

Do not remove Calendar compatibility references until the actual intended Calendar backend/API shape is confirmed.

## Observed result

- `/calendar` shell returned HTTP 200 from the laptop wrapper.
- `/api/calendar` returned HTTP 404 Not Found, not HTTP 502.
- `/api/calendar/events` returned HTTP 404 Not Found, not HTTP 502.
- `POST /api/calendar/events` returned HTTP 404 Not Found, not HTTP 502.
- `edge-queue-public-gateway.service` remains inactive and disabled.
- Port `7071` has no listener.

## Decision

Calendar is currently a wrapper/planning page, not a completed backend API.

Keep Calendar route compatibility references for now. Do not remove or rename Calendar paths until the intended backend API shape is implemented.
