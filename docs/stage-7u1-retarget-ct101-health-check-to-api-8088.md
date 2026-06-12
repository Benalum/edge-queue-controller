# Stage 7U-1 Retarget CT101 Health Check To API 8088

Stage 7U-1 retargets stale CT101 health and AI-platform URLs from the retired frontend port `3010` to the active API port `8088`.

This stage does not restart the live controller.

This stage does not change router behavior.

This stage does not change frontend behavior.

## Finding

The controller health endpoint was reporting:

- `host_online=false`
- `host_check_url=http://100.88.245.33:3010`
- `host_detail=ConnectError('All connection attempts failed')`

CT101 was reachable through Tailscale.

The active CT101 listeners included:

- `100.88.245.33:8088` for `ai-platform-api`
- `100.88.245.33:11434` for `ollama`

Nothing was listening on:

- `100.88.245.33:3010`

The `ai-platform-frontend` container was running but had no published `3010` port.

## Change

The `.env` non-secret URL values were updated:

- `HOST_CHECK_URL=http://100.88.245.33:8088/health`
- `AI_PLATFORM_BASE_URL=http://100.88.245.33:8088`
- `AI_PLATFORM_EDGE_INGEST_URL=http://100.88.245.33:8088/api/backend/internal/edge/jobs`

## Safety boundary

This stage only updates configuration and adds smoke coverage.

The live controller process will not use this change until it is restarted later.

A temporary controller process can validate the new config without interrupting the live website.
