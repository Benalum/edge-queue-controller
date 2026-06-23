# Stage 16 E3Z-ET-R2 installed-unit proof failure cleanup diagnostic no-retry

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-ES-R2.
- Base HEAD/origin/main: `a309b8d`.
- Base tag: `controller-stage-16-e3z-es-r2-guarded-ct101-unit-install-default-off-verification-2026-06-22`.

## Why this stage exists

E3Z-ET attempted the first installed-unit one-tick runtime proof using fresh job 53.

The installed timer path fired and started the matching installed service instance, but the worker failed with:

```text
REFUSE_WORKER_EXACT_MARKER_MISMATCH
```

Because a model attempt occurred, job 53 must not be reset, deleted, or retried silently.

## E3Z-ET failure evidence

- Fresh job id: `53`.
- Marker: `E3Z-ET-INSTALLED-TIMER-QWEN25-ONE-TICK-OK`.
- Expected response sha256: `b57a6763296de36ae40200fc78c6cf02242a61702a992599d74e6a9db4b4b99f`.
- Timer instance: `edge-ct101-exact-job-worker@53.timer`.
- Service instance: `edge-ct101-exact-job-worker@53.service`.
- Service result before cleanup: `exit-code`.
- Service exec status before cleanup: `1`.
- Worker refusal: `REFUSE_WORKER_EXACT_MARKER_MISMATCH`.

Read-only CT203 evidence after failure:

```text
quick_check_after_et_failure=ok
job53_status_after_et_failure=running
job53_attempts_after_et_failure=1
job53_result_rows_after_et_failure=0
jobs_37_52_completed_with_one_result_after_et_failure=16
max_job_id_after_et_failure=53
```

## Cleanup scope

This cleanup stage stopped only the exact ET job 53 installed timer/service instance.

It did not:

- reset job 53,
- delete job 53,
- retry job 53,
- write the CT203 database,
- insert a new job,
- apply schema,
- enable service or timer templates,
- reload systemd,
- write unit files,
- enable persistent scheduler or timer dispatch,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- restart CTs or VMs,
- call Ollama,
- pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Cleanup result

```text
cleanup_ssh_rc=0
cleanup_acceptance_pass=true
stop_timer_rc=0
stop_service_rc=0
timer_instance_active_after_cleanup=inactive
timer_instance_enabled_after_cleanup=disabled
service_instance_active_after_cleanup=failed
service_instance_result_after_cleanup=exit-code
edge_service_after_cleanup_active=inactive
edge_service_after_cleanup_enabled=disabled
active_exact_job_units_after_cleanup=0
active_exact_job_timers_after_cleanup=0
```

## Acceptance result

E3Z-ET-R2 passed as a failure cleanup and diagnostic checkpoint.

The installed timer/service path was returned to default-off posture:

- the job 53 timer instance is inactive and disabled,
- no exact-job worker units are active,
- no exact-job timers are active,
- the permanent CT101 worker service remains inactive/disabled,
- jobs 37 through 52 remain completed with one result row each,
- job 53 remains preserved as failed-proof evidence with status `running`, attempts `1`, and result rows `0`.

## Diagnosis

The installed unit path itself fired correctly:

- the installed timer instance started,
- the matching installed service instance started,
- the worker reached the model-response validation path.

The proof failed because the model output did not exactly match the marker.

This is a model-response exactness failure, not evidence that the installed timer failed to fire.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EU`.

Purpose: create a no-apply acceptance contract for a safer installed-unit retry strategy using a fresh job, while preserving job 53 as evidence and tightening the exact-marker prompt/verification strategy.

Any future runtime retry must use a fresh job id and separate explicit approval. Job 53 must not be reset, deleted, or retried silently.
