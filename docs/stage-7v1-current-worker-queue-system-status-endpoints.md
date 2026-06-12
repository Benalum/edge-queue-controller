# Stage 7V-1 Current Worker Queue System Status Endpoints

Stage 7V-1 records the current correct worker, queue, and system status endpoints.

This stage does not change runtime behavior.

This stage does not restart the controller.

This stage does not change router behavior.

## Finding

The old guessed endpoint is not valid:

- `GET /api/system/status` returns HTTP 404.

The current correct system endpoint is:

- `GET /system/status`

The current system endpoint returns:

- controller node status
- pveso status
- CT101 status
- Study API status
- CT101 laptop queue worker status
- normalized infrastructure/platform blocks

## Current live state observed

`GET /system/status` returned:

- `overall_state=online`
- controller node online
- pveso online
- CT101 online
- Study API online
- CT101 laptop queue worker online

The CT101 laptop queue worker reported:

- service active
- preflight ok
- paused no
- model `gemma4:e4b`
- queued 0
- running 0
- complete 38
- failed 5

## Internal queue API boundary

The route:

- `GET /internal/laptop-queue/summary`

is an internal worker route and requires:

- `X-Laptop-Queue-Token`

A 401 response without the token is expected and correct.

## Current route notes

Useful status routes:

- `GET /health`
- `GET /system/status`
- `GET /system/local-health`
- `GET /public/status`
- `GET /queue/summary`
- `GET /workers/registry`
- `GET /workers/events`
- `GET /api/chat/queue/status` requires an authenticated bearer token
- `GET /public/chat/queue/status` may also be auth-gated depending on current policy

Power automation routes are POST routes, not GET routes:

- `POST /power/auto/status`
- `POST /power/auto/tick`

## Safety boundary

This stage only documents and verifies endpoint status.

It does not modify queue state.

It does not dispatch router actions.

It does not call models.

It does not restart services.

## Auth boundary

`GET /api/chat/queue/status` returned HTTP 401 without a bearer token. That is treated as an expected authentication boundary, not an endpoint failure.
