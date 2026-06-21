# Stage 16 E3K-B-R2 — Complete DB From Captured Adapter Result

Date: 2026-06-20

## Scope

Recovered E3K-B after the first E3K-B attempt successfully ran the adapter/model call but failed before DB mutation because the generic insert builder skipped `job_results.job_id`, which is the primary key in the live schema.

## Important recovery detail

E3K-B-R2 did **not** run the model again.

It reused the captured successful E3K-B adapter output:

- Response: `APC_E3K_B_OK`
- Response length: `12`
- Elapsed seconds: `39`
- Eval count: `8`
- Remote adapter run dir: `/root/apc-one-shot-model-adapter-20260621T042455Z`

## Approval

`APPROVE_STAGE_16_E3K_B_MANUALLY_COMPLETE_SYNTHETIC_JOB_25_WITH_ONE_ADAPTER_MODEL_CALL_UPDATE_ONE_JOBS_ROW_INSERT_ONE_JOB_RESULTS_ROW_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED`

## Target job

- Job ID: `25`
- Original status before R2: `queued`
- Final status after R2: `completed`
- Job type: `stage16_e3k_synthetic_model_smoke`
- Requested model: `qwen2.5:32b-instruct-q4_K_M`
- Original marker: `APC_STAGE16_E3K_A_SYNTHETIC_QUEUED_JOB_ONLY`

## DB mutation performed

- Updated exactly one `jobs` row: `id=25`
- Inserted exactly one `job_results` row for `job_id=25`
- Inserted job result rowid: `25`
- Job 25 attempts after: `1`
- Result marker: `APC_STAGE16_E3K_B_MANUAL_COMPLETION_RESULT`

## Count result

Before R2 DB mutation:

- `jobs=24`
- `job_results=6`
- `job_results_for_job_25=0`

After R2 DB mutation:

- `jobs=24`
- `job_results=7`
- `job_results_for_job_25=1`
- `job_results_marker_matches_for_job_25=1`

## Explicit non-actions in R2

- No additional model call.
- No approved adapter execution.
- No prompt/completion/generate/chat/embed calls.
- No additional job insert/update/delete.
- No additional `job_results` insert/update/delete.
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

## Guards preserved

- Public routes remained healthy.
- CT203 service remained active.
- CT203 DB integrity remained `ok`.
- PVESO Ollama remained active and localhost-only.
- CT101 remained stopped/onboot=0.
- Router/worker metadata counts remained unchanged:
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`

## Next recommended stage

Stage 16 E3L should be a no-apply design for a repeatable manual DB-backed job completion helper, or this checkpoint can be used for a source refresh/new-chat handoff.
