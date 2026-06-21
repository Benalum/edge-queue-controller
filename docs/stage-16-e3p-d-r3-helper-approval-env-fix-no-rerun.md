# Stage 16 E3P-D-R3 — Helper Approval Env Fix No-Rerun

## Purpose

Stage 16 E3P-D-R3 fixes the second E3P-D execution refusal.

E3P-D-R2 reached the dispatch step after PVESO preflight passed, but the manual helper refused with exit code `64` because the operator artifact did not pass the nested helper approval environment variable.

## Root cause

The operator artifact had its own approval gate:

`APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION`

The manual helper has a separate legacy approval gate:

`APPROVE_STAGE_16_E3M_B_RUN_MANUAL_COMPLETION_HELPER_FOR_ONE_QUEUED_JOB_ONE_MODEL_CALL_ONE_JOB_UPDATE_ONE_JOB_RESULT_INSERT_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED`

The operator artifact validated the E3P-D approval, but then invoked:

`ops/model/manual-complete-queued-job-via-pveso-adapter.sh --job-id 27`

without setting:

`APC_MANUAL_COMPLETION_APPROVAL`

The helper correctly refused before helper/model/DB completion.

## Scope

Allowed in this phase:

- Read-only CT203 DB classification for job 27.
- Read-only PVESO runner/listener/CT101 classification.
- Patch the operator artifact to pass the nested helper approval explicitly.
- Add this recovery document and smoke.
- Commit, tag, and push.

Denied in this phase:

- No DB write.
- No job completion.
- No `job_results` insert.
- No helper execution.
- No adapter execution.
- No operator dispatch execution.
- No model endpoint call.
- No scheduler activation.
- No persistent worker activation.
- No CT101 start.
- No public PVESO/Ollama exposure.

## Preserved runtime state

Read-only classification confirmed:

- Job 27 status: `queued`
- Job 27 attempts: `0`
- Job 27 result rows: `0`
- Total jobs: `26`
- Total job_results: `8`
- Worker count: `2`
- DB integrity: `ok`
- PVESO Ollama active: yes
- PVESO Ollama localhost-only: yes
- PVESO runner count: `0`
- CT101 stopped/onboot=0: yes

## Patch

The operator artifact now defines:

`HELPER_REQUIRED_APPROVAL`

and invokes the manual helper with:

`APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"`

This bridges the E3P-D operator approval to the older E3M-B manual helper approval without changing the helper itself.

## Next step

E3P-D may be retried against job 27 only after explicit runtime approval is re-confirmed.

Before retrying, verify again that job 27 is queued with zero result rows and PVESO runner count is zero.

Do not rerun against jobs 25 or 26.
