# Stage 16 E3P-D-R6 — Helper JOB_ID Env Fix No-Rerun

## Purpose

Stage 16 E3P-D-R6 fixes the next E3P-D runtime refusal found by the compact heartbeat run.

E3P-D-R5 reached the manual helper with approval, but the helper refused with exit code `65` because it expects the target job as environment variable `JOB_ID`, not only as CLI argument `--job-id`.

## Root cause

The operator artifact invoked the manual helper with:

`--job-id 27`

but did not also set:

`JOB_ID=27`

The manual helper printed:

`job_id_guard=FAIL missing JOB_ID`

and exited before adapter/model/DB completion.

## Scope

Allowed in this phase:

- Read-only CT203 DB classification for job 27.
- Read-only PVESO runner/listener/CT101 classification.
- Patch the operator artifact to pass `JOB_ID="$JOB_ID"` into the manual helper environment.
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

The operator artifact now invokes the manual helper with both:

`APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"`

and:

`JOB_ID="$JOB_ID"`

before the `timeout ... bash "$HELPER_PATH"` command.

## Next step

E3P-D may be retried against job 27 only after explicit runtime approval is re-confirmed.

Before retrying, verify again that job 27 is queued with zero result rows and PVESO runner count is zero.

Do not rerun against jobs 25 or 26.
