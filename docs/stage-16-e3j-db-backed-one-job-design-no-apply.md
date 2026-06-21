# Stage 16 E3J — DB-Backed One-Job Design No-Apply

Date: 2026-06-20

## Scope

Design the first DB-backed one-job path after E3I proved the gated one-shot PVESO adapter can run once without DB writes or worker/scheduler activation.

## Current checkpoint

- Repo HEAD before E3J: `5cf77bb`
- Adapter: `ops/model/pveso-one-shot-generate.sh`
- CT203 DB path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- PVESO Ollama remains active and localhost-only.
- CT101 remains stopped/onboot=0.
- Public login/API routes remain healthy.
- CT203 DB guard counts remain unchanged.

## Read-only schema inspection

E3J inspected the live CT203 DB in read-only mode.

- `jobs` columns detected: `11`
- `job_results` columns detected: `7`
- DB integrity: `ok`
- Source scan lines captured: `788`

No prompts, payload contents, secrets, or full result JSON bodies were printed.

## Design decision

The first DB-backed model path should be a **manual one-job lifecycle**, not scheduler-dispatched.

The path should remain separate from persistent worker activation:

1. Insert exactly one synthetic test job.
2. Use a stage-specific marker in the prompt/body, such as `APC_E3K_OK`.
3. Do not expose any public model route.
4. Do not turn on the scheduler.
5. Do not register or mutate persistent workers.
6. Execute the existing gated adapter once from a controlled PPB phase.
7. Store one result only if explicitly approved.
8. Verify before/after DB counts and exact new row IDs.
9. Verify public routes and CT101 state before and after.
10. Leave PVESO Ollama localhost-only.

## Proposed E3K apply design

E3K should require explicit approval because it will write to the CT203 DB.

Recommended E3K split:

### E3K-A — insert one queued synthetic test job only

Allowed:
- One DB insert into `jobs`.
- No model call.
- No scheduler activation.
- No worker mutation.
- No public exposure.

Expected after:
- `jobs` count increases from `23` to `24`.
- `job_results` remains `6`.
- The new job is clearly marked as a Stage 16 E3K synthetic test job.

### E3K-B — manually complete the one test job through adapter

Allowed only after separate approval:
- Read the one E3K test job.
- Run the adapter once.
- Update that one job and/or insert one `job_results` row only if explicitly approved.
- No scheduler activation.
- No persistent worker activation.

Expected after:
- `jobs` remains `24`.
- `job_results` increases from `6` to `7` if result insert is approved.
- The E3K job is completed/failed deterministically depending on adapter result.

## Guardrail requirements for any DB-write stage

Before any E3K DB write:

- Confirm repo HEAD/tag.
- Confirm public routes:
  - `/` HTTP 200
  - `/login` HTTP 200
  - `/api/me` HTTP 401
  - `/api/system/status` HTTP 200
  - `/system/status` HTTP 200
- Confirm CT203 service active and DB integrity `ok`.
- Capture exact pre-counts for:
  - `user_sessions`
  - `jobs`
  - `job_results`
  - `router_logs`
  - `router_resolution_steps`
  - `router_feedback`
  - `workers`
  - `worker_events`
- Confirm PVESO Ollama active and localhost-only.
- Confirm CT101 stopped/onboot=0.

## Explicit non-actions in E3J

- No job insert/update/delete.
- No job result insert/update/delete.
- No prompt/completion/generate/chat/embed calls.
- No approved adapter execution.
- No DB writes.
- No worker registration mutation.
- No worker activation.
- No scheduler activation.
- No model pull/download.
- No CT101 start.
- No CT/VM start/stop/restart.
- No service restart/reload/start/stop.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Next recommended stage

Stage 16 E3K-A should require explicit approval to insert exactly one synthetic queued DB job and nothing else.
