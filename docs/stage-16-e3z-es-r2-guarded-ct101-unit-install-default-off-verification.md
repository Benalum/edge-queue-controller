# Stage 16 E3Z-ES-R2 guarded CT101 unit install default-off verification

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-ER.
- Base HEAD/origin/main: `de99901`.
- Base tag: `controller-stage-16-e3z-er-guarded-installed-timer-service-path-contract-no-apply-2026-06-22`.
- Approval: `APPROVE_STAGE_16_E3Z_ES_INSTALL_GUARDED_CT101_TIMER_SERVICE_UNITS_DEFAULT_OFF_NO_START_NO_ENABLE`.

## Why R2 was needed

E3Z-ES-R1 installed the reviewed CT101 systemd service/timer template files and ran `systemctl daemon-reload`, but its verifier queried the bare template names and did not receive load-state metadata.

R1 failed after installation, but failed safely:

- no CT203 DB write,
- no job insert,
- no job reset or delete,
- no schema apply,
- no service start,
- no timer start,
- no service enablement,
- no timer enablement,
- no scheduler activation,
- no persistent worker enablement,
- no queue drain,
- no Docker mutation,
- no CT or VM restart,
- no Ollama call,
- no model pull.

R2 performed post-install verification through inactive instance names and did not write the unit files again.

## Mutation scope used by R2

R2 used:

- post-install CT101 unit-file verification,
- `systemd-analyze verify`,
- systemd metadata checks through `edge-ct101-exact-job-worker@0.service` and `edge-ct101-exact-job-worker@0.timer`,
- CT203 read-only DB guard,
- CT101 service/timer default-off verification,
- repo doc/smoke/commit/tag/push checkpoint.

R2 did not:

- write CT101 unit files,
- run `systemctl daemon-reload`,
- start or enable service units,
- start or enable timer units,
- insert or mutate jobs,
- call Ollama,
- mutate Docker,
- restart CTs or VMs.

## Installed unit templates

- Service template: `edge-ct101-exact-job-worker@.service`
- Service path: `/etc/systemd/system/edge-ct101-exact-job-worker@.service`
- Service sha256: `16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e`
- Service instance verified: `edge-ct101-exact-job-worker@0.service`
- Service instance load state: `loaded`
- Service instance unit-file state: `static`

- Timer template: `edge-ct101-exact-job-worker@.timer`
- Timer path: `/etc/systemd/system/edge-ct101-exact-job-worker@.timer`
- Timer sha256: `7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390`
- Timer instance verified: `edge-ct101-exact-job-worker@0.timer`
- Timer instance load state: `loaded`
- Timer instance unit-file state: `disabled`
- Timer instance enabled state: `disabled`

## Guarded worker path

The installed service template preserves the known-good worker shape:

- `EDGE_WORKER_ENABLED=1`
- `EDGE_MAX_JOBS_PER_LOOP=1`
- `EDGE_CLAIM_POLICY=one_at_a_time`
- `EDGE_ALLOW_MODEL_CONCURRENCY=0`
- `EDGE_ALLOWED_JOB_IDS="$JOB_ID"`
- `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`
- `--once --job-id "$JOB_ID"`

The service template refuses non-numeric or missing job ids before invoking the worker.

The timer template maps an exact timer instance to the matching exact service instance:

- `Unit=edge-ct101-exact-job-worker@%i.service`
- `OnActiveSec=3s`
- `AccuracySec=1s`
- `Persistent=false`

## Verification result

```text
verify_ssh_rc=0
systemd_analyze_verify_rc=0
r2_acceptance_pass=true
active_exact_job_units_after=0
ct101_queue_timer_rows_after=0
edge_service_after_active=inactive
edge_service_after_enabled=disabled
```

## DB guard result

```text
quick_check_after_es_r1=ok
jobs_37_52_seen_after_es_r1=16
jobs_37_52_completed_with_one_result_after_es_r1=16
max_job_id_after_es_r1=52
job52_status_after_es_r1=completed
job52_result_rows_after_es_r1=1
```

## Acceptance result

E3Z-ES-R2 passed.

The guarded installed CT101 service/timer unit templates are present, hash-pinned, systemd-verified, and default-off:

- no exact-job worker unit is active,
- the timer instance is disabled,
- CT101 queue timer rows remain 0,
- the permanent CT101 worker service remains inactive/disabled,
- jobs 37 through 52 remain completed with one result row each,
- no jobs were inserted or mutated,
- no Ollama call was made.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-ET`.

Purpose: perform the first installed-unit one-tick runtime proof with one fresh exact-marker job, using the installed disabled timer template by starting exactly one timer instance for exactly one approved job id.

E3Z-ET requires explicit runtime approval because it will insert one fresh job, start one installed timer instance, and call Ollama once.
