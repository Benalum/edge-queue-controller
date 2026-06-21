# Stage 16 E3L — Repeatable Manual Completion Helper Design No-Apply

Date: 2026-06-20

## Scope

Design the next repeatable manual DB-backed model job completion helper after E3K-B-R2 proved the first complete lifecycle:

1. Existing queued job in CT203 DB.
2. One gated adapter/model call.
3. One `jobs` row update.
4. One `job_results` row insert.
5. No scheduler activation.
6. No persistent worker activation.

## Current verified lifecycle state

- Repo HEAD before E3L: `56b2cc7`
- Completed synthetic job: `25`
- `jobs=24`
- `job_results=7`
- `job_results_for_job_25=1`
- Job 25 status: `completed`
- Job 25 attempts: `1`
- Job 25 model: `qwen2.5:32b-instruct-q4_K_M`
- Job 25 result response length: `12`
- Result marker: `APC_STAGE16_E3K_B_MANUAL_COMPLETION_RESULT`
- Repo/source inventory lines captured: `617`

## Design decision

The next helper should be a **manual single-job completion helper**, not a scheduler and not a persistent worker.

Recommended file:

- `ops/model/manual-complete-queued-job-via-pveso-adapter.sh`

Recommended properties:

1. Require an explicit approval environment variable.
2. Require a concrete `JOB_ID`.
3. Require the target DB job to be:
   - present,
   - `status='queued'`,
   - model-supported,
   - not already represented in `job_results`.
4. Read the job prompt/model from CT203 DB in read-only preflight.
5. Run the existing `ops/model/pveso-one-shot-generate.sh` exactly once with approval.
6. Decode adapter output into a structured JSON payload.
7. Update exactly one `jobs` row.
8. Insert exactly one `job_results` row.
9. Verify exact before/after counts.
10. Refuse if scheduler/worker activation env flags are detected.
11. Refuse if CT101 is not stopped/onboot=0.
12. Refuse if PVESO Ollama is not localhost-only.
13. Keep public routes and CT203 service health guarded before and after.

## Helper must not do these things

- It must not enable/start/restart any service.
- It must not start CT101.
- It must not create more than one result row.
- It must not process more than one job.
- It must not activate scheduler dispatch.
- It must not register/activate persistent workers.
- It must not expose a public model endpoint.
- It must not pull/download models.
- It must not mount/unlock private storage.

## Recommended next split

### E3M-A — add helper no-run

Repo-only:
- Add helper script.
- Add smoke proving approval gate and read-only guards.
- No model call.
- No DB write.

### E3M-B — run helper against one new synthetic job

Separate approval:
- Insert one new queued synthetic job or select a safe existing queued test job.
- Run helper once.
- Verify one jobs-row update and one job_results insert.
- No scheduler/worker activation.

## Explicit non-actions in E3L

- No DB writes.
- No job insert/update/delete.
- No `job_results` insert/update/delete.
- No model call.
- No approved adapter execution.
- No prompt/completion/generate/chat/embed calls.
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

Stage 16 E3M-A can add the repeatable helper script no-run, with no DB write and no model call.
