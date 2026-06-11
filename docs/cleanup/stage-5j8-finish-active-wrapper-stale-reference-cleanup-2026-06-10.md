# Stage 5J-8 Finish Active Wrapper Stale Reference Cleanup — 2026-06-10

## Purpose

Finish the active wrapper cleanup after Stage 5J-7 left a stale unused `GATEWAY` env line and old public-gateway comments.

## Result

- Removed the unused `GATEWAY = EDGE_PUBLIC_GATEWAY_URL -> 7071` line from `frontend/wrapper-ui/dev_server.py`.
- Updated active wrapper comments away from public-gateway/source-of-truth wording.
- Kept `public_gateway.py` in the repository.
- Kept `cloudflare/edge-public-proxy/*` in the repository.
- Kept `/api/backend/*` compatibility bridge code.

## Runtime confirmation

- `/study`, `/chat`, `/companion`, and `/calendar` still load.
- `/api/system/status` still responds.
- Port `7071` still has no listener.
