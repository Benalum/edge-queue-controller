# Phase 14J-KQ — CT203 execution gate audit

Date: 2026-06-18

## Scope

This checkpoint records a read-only audit of risky execution gates on CT203 after the PVEW-contained controller migration, login repair, and fresh encrypted backup.

## Result

Risky legacy execution paths are present in source, but their runtime gates are disabled.

## Verified platform state

- VM200 status: running.
- CT203 status: running.
- CT204 status: stopped.
- `edge-queue-controller.service` is active.
- `edge-queue-controller.service` is enabled.
- CT203 SQLite DB integrity check returned `ok`.

## Verified execution gates

The following CT203 runtime gate values were observed:

- `EDGE_DRY_RUN=true`
- `EDGE_FORWARD_JOBS=false`
- `EDGE_POWER_DRY_RUN=true`
- `EDGE_POWER_AUTO_TICK_FULL=false`
- `EDGE_POWER_AUTO_STOP_WORKERS=false`
- `EDGE_POWER_AUTO_SHUTDOWN_HOST=false`
- `EDGE_POWER_AUTO_START_WORKERS=false`
- `EDGE_POWER_EXECUTE_STOPS=false`
- `EDGE_POWER_EXECUTE_HOST_SHUTDOWN=false`
- `EDGE_POWER_EXECUTE_WAKE=false`
- `EDGE_POWER_EXECUTE_WAKE_AND_START=false`
- `EDGE_POWER_EXECUTE_START_WORKERS=false`
- `EDGE_DIRECT_OLLAMA_FORWARD=<unset>`
- `WORKER_START_ENABLED=false`
- `WORKER_START_DRY_RUN=true`
- `WEB_POWER_POLICY_EXECUTE_WAKE=false`
- `WEB_POWER_POLICY_EXECUTE_CONTAINERS=false`
- `WEB_POWER_POLICY_EXECUTE_SHUTDOWN=false`

## Interpretation

CT203 is serving the public controller path, but it is not currently authorized to:

- forward jobs to model/Ollama endpoints,
- start workers,
- stop containers or hosts,
- wake Proxmox/worker infrastructure,
- execute web-presence power policy actions.

This keeps the PVEW-contained public controller safe while legacy laptop/PVESO/CT101 code paths remain present in the active source.

## Follow-up

A later cleanup/refactor phase should remove or retire obsolete laptop/PVESO/CT101 wording and source paths after the PVEW-contained runtime is stable.
