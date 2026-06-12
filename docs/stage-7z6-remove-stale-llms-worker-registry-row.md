# Stage 7Z-6 Remove Stale llms-worker-1 Registry Row

Stage 7Z-6 removed the stale local worker registry row for `llms-worker-1`.

## Why

The old CT101 edge heartbeat was retired in Stage 7Z-4.

That old heartbeat used:

- `ai-platform-edge-heartbeat.timer`
- `POST /workers/heartbeat`
- worker id: `llms-worker-1`
- target name: `llms_ollama`

It reported unhealthy because it checked the obsolete Docker-network Ollama URL:

- `http://ollama:11434`

The active worker path is now the managed laptop queue worker:

- `ai-platform-laptop-queue-worker.service`
- `POST /internal/laptop-queue/workers/register`
- `POST /internal/laptop-queue/workers/heartbeat`
- `POST /internal/laptop-queue/jobs/claim`
- worker id: `ct101-stage5g21-managed-browser`

## Backup

Before deleting the stale row, the SQLite database was backed up:

- `edge_queue.sqlite3.bak-stage7z6-remove-stale-worker-20260612-170518`

## Change

Deleted only this row from the local SQLite `workers` table:

- `worker_id = 'llms-worker-1'`

The `worker_events` history was kept.

## Verification

After cleanup:

- `/workers/registry` reported `total=0`
- `/workers/registry` reported `unhealthy=0`
- `/workers/remediation/tick` reported `worker_count=0`
- all normalized platform cards stayed `online`
- CT101 Laptop Queue Worker stayed `online`
- old `/workers/heartbeat` stayed quiet
- managed `/internal/laptop-queue/...` activity continued
- legacy laptop `/tick` scheduler timer stayed disabled/inactive
- modern power/remediation timers stayed active

## Decision

Keep the stale `llms-worker-1` registry row removed.

The managed CT101 laptop queue worker is the active worker path.
