# Stage 16 E3M-A — Add Manual Completion Helper No-Run

Date: 2026-06-20

## Scope

Add a repeatable manual DB-backed queued-job completion helper, without executing it.

## Helper

- Path: `ops/model/manual-complete-queued-job-via-pveso-adapter.sh`
- Existing adapter used by helper: `ops/model/pveso-one-shot-generate.sh`
- Future helper approval gate:
  - `APPROVE_STAGE_16_E3M_B_RUN_MANUAL_COMPLETION_HELPER_FOR_ONE_QUEUED_JOB_ONE_MODEL_CALL_ONE_JOB_UPDATE_ONE_JOB_RESULT_INSERT_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED`

## Current lifecycle checkpoint before helper addition

- `jobs=24`
- `job_results=7`
- Job `25` is completed.
- Job `25` has exactly one result row.
- Adapter remains gated.
- PVESO Ollama remains active and localhost-only.
- CT101 remains stopped/onboot=0.

## Helper intent

The helper is designed for a future E3M-B approval boundary. When approved later, it should:

1. Require a concrete `JOB_ID`.
2. Require an explicit approval environment variable.
3. Read exactly one queued job from CT203 DB.
4. Refuse if the job already has a `job_results` row.
5. Run the existing PVESO one-shot adapter once.
6. Update exactly one `jobs` row.
7. Insert exactly one `job_results` row.
8. Refuse unsafe repeated completion attempts.

## Explicit non-actions in E3M-A

- The helper was not executed with approval.
- No DB write.
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

Stage 16 E3M-B should be a separate explicit approval boundary. It should either insert one new queued synthetic job and run the helper once, or use a pre-existing safe queued test job if one is intentionally created first.
