# Stage 5G-28 — Runtime invariant smoke

## Goal

Prevent regressions in the runtime configuration required for live browser queued chat.

## Why

Stage 5G-27 proved the full live browser queued-chat path works:

Browser queued submit → laptop queue → managed CT101 worker → Ollama → completed browser response.

During validation, several runtime issues were found and repaired:

- controller was accidentally listening only on 127.0.0.1:7070
- wrapper was missing WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1
- CT101 worker token file was missing LAPTOP_QUEUE_INTERNAL_TOKEN
- CT101 worker base URL must point to the laptop Tailscale IP on port 7070

## Runtime invariants verified

This smoke verifies:

- controller is listening on 0.0.0.0:7070
- controller exposes /health locally
- controller runtime has LAPTOP_QUEUE_INTERNAL_TOKEN
- wrapper is listening on 127.0.0.1:8787
- wrapper runtime has WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1
- wrapper runtime has EDGE_CONTROLLER_URL=http://127.0.0.1:7070
- wrapper runtime has EDGE_TRUSTED_PROXY_SECRET
- CT101 worker env points to the laptop Tailscale URL on port 7070
- CT101 worker token file contains LAPTOP_QUEUE_INTERNAL_TOKEN
- CT101 can reach laptop /health over Tailscale
- managed CT101 worker service is active
- wrapper system status reports ct101-laptop-queue-worker online

## Safety

This stage does not change runtime behavior.

This stage does not rotate secrets.

This stage does not change worker concurrency.

This stage does not expose secret values.

This stage only verifies runtime configuration and health.
