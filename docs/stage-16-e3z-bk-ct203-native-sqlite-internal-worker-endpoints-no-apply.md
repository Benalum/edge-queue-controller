# Stage 16 E3Z-BK — CT203 Native SQLite Internal Worker Endpoints No-Apply Design

## Purpose

Design the smallest safe CT203-native replacement for the legacy `/internal/laptop-queue/*` worker routes.

This stage is no-apply. It does not add routes, alter schemas, start CT101 worker services, start Docker, call Ollama, mutate jobs, or activate scheduler/timer.

## Finding

E3Z-BI/BJ showed that CT101 can reach CT203 and token authentication can now reach the old internal route layer, but the old `/internal/laptop-queue/*` implementation still depends on the retired Postgres env file:

`/root/.config/ai-platform-controller/postgres.env`

Do not revive Postgres. CT203 authority is SQLite:

`/var/lib/edge-queue-controller/edge_queue.sqlite3`

## Design decision

Add a new CT203-native SQLite-backed internal worker API instead of reusing the old Postgres-backed implementation.

Proposed namespace:

- `GET /internal/edge-worker/summary`
- `POST /internal/edge-worker/workers/register`
- `POST /internal/edge-worker/workers/heartbeat`
- `POST /internal/edge-worker/jobs/claim`
- `POST /internal/edge-worker/jobs/{job_id}/complete`
- `POST /internal/edge-worker/jobs/{job_id}/fail`

## Default gate

The new endpoint set must default disabled:

`EDGE_CT203_SQLITE_WORKER_API_ENABLED=0`

When disabled, routes must return a controlled refusal.

When enabled, routes require the existing internal header:

`X-Laptop-Queue-Token`

The header name may stay for CT101 client compatibility, even though the new route namespace is CT203-native.

## Claim rules

The claim endpoint must:

1. Use a single SQLite transaction.
2. Claim only `status='queued'` jobs.
3. For first proof, claim only exact allowlisted job IDs.
4. Atomically update the selected job to `status='running'`.
5. Increment `attempts`.
6. Set `assigned_worker_id`, `started_at`, and `updated_at` only when those columns exist.
7. Return the claimed job payload.
8. Never claim job 34 or retired proof jobs.

## Completion rules

The complete endpoint must:

1. Verify the job is currently `running`.
2. Verify worker ownership if the schema supports it.
3. Insert one `job_results` row.
4. Update the job to `completed`.
5. Set `finished_at` and `updated_at` only when those columns exist.
6. Preserve deterministic proof markers for proof jobs.

## CT101 retarget path

Do not enable the persistent CT101 worker service yet.

First proof should be one bounded run:

- Keep ai-platform-laptop-queue-worker.service masked/inactive.
- Point a one-shot env at `LAPTOP_QUEUE_BASE_URL=http://192.168.0.250:7070`.
- Keep `LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1`.
- Use exact allowlisted job IDs.
- Prefer deterministic/mock completion first.
- Only after CT203-native claim/complete is proven, move to Ollama execution.

## Docker/Ollama boundary

Do not start Docker or Ollama for the first CT203-native API proof.

Docker/Ollama activation remains separately gated because CT101 has existing Docker containers with `restart_policy=unless-stopped`.

## Next stage

Stage 16 E3Z-BL should implement the disabled CT203-native SQLite internal worker endpoint skeleton behind `EDGE_CT203_SQLITE_WORKER_API_ENABLED=0`, with no runtime activation.
