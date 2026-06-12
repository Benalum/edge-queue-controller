# Stage 7Z-4 Disable Old CT101 Edge Heartbeat

Stage 7Z-4 disables the old CT101 edge heartbeat timer while keeping the managed laptop queue worker online.

## Problem

CT101 was still running the legacy edge heartbeat path:

- `ai-platform-edge-heartbeat.timer`
- `ai-platform-edge-heartbeat.service`
- `POST /workers/heartbeat`
- worker id: `llms-worker-1`
- target name: `llms_ollama`

That old heartbeat reported unhealthy because it checked the obsolete Docker-network Ollama URL:

- `http://ollama:11434`

The current managed worker uses the newer laptop queue path:

- `ai-platform-laptop-queue-worker.service`
- `POST /internal/laptop-queue/workers/register`
- `POST /internal/laptop-queue/workers/heartbeat`
- `POST /internal/laptop-queue/jobs/claim`
- worker id: `ct101-stage5g21-managed-browser`
- Ollama URL: `http://100.88.245.33:11434`

## Change

Disabled only the old CT101 edge heartbeat timer/service:

- `ai-platform-edge-heartbeat.timer`
- `ai-platform-edge-heartbeat.service`

The managed laptop queue worker remained enabled and active.

## Verification

After disabling the old timer:

- No new `POST /workers/heartbeat` lines appeared.
- Managed laptop queue register/heartbeat/claim calls continued.
- Platform status remained `online`.
- CT101 Laptop Queue Worker remained `online`.
- Legacy laptop `/tick` scheduler timer remained disabled/inactive.
- Modern power/remediation timers remained active.

## Decision

Keep the old edge heartbeat disabled.

The managed laptop queue worker is the active worker path.
