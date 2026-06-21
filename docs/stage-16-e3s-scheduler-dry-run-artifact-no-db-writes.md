# Stage 16 E3S — Scheduler Dry-Run Artifact, No DB Writes

## Purpose

E3S adds a scheduler dry-run artifact that can inspect the CT203 SQLite queue DB in read-only mode and print what the scheduler would claim later.

This is not scheduler activation.

## Safety boundary

Allowed:

- repo artifact creation
- repo docs/smoke creation
- read-only DB inspection when the artifact is run manually later

Denied:

- DB write
- DB claim
- claim/lease schema apply
- helper call
- PVESO adapter call
- operator dispatch call
- model endpoint call
- job completion
- job_result insert
- scheduler activation
- persistent worker activation
- lane worker activation
- CT101 start
- service/CT/VM/Cloudflare/private-storage mutation

## Artifact

Script:

```text
ops/scheduler/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.pyRun with Project Pilot
Running...

Default DB path when run inside CT203:

/var/lib/edge-queue-controller/edge_queue.sqlite3

Override:

APC_E3S_DB_PATH=/path/to/edge_queue.sqlite3 \
  ./ops/scheduler/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.py
Expected output markers

The artifact prints:

NO_DB_WRITE
DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
WOULD_CLAIM ...

If there is no eligible queued job, it prints:

WOULD_CLAIM none
Candidate rules

The dry-run only considers queued jobs. It rejects jobs that already have result rows, jobs with non-allowlisted models, and jobs whose lane cannot be mapped.

Current allowlisted PVESO models:

qwen2.5:32b-instruct-q4_K_M
qwen2.5-coder:32b-instruct-q4_K_M
Next phases

E3T/E3U remain separate future runtime/DB phases and require explicit approval. Do not reuse job 27.
