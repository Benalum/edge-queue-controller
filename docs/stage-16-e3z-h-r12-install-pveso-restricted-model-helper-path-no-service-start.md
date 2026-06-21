# Stage 16 E3Z-H R12 — Install PVESO Restricted Model Helper Path, No Service Start

## Phase status

MUTATION_SCOPE: CT203 key/env plus PVESO forced-command helper install and preflight-only validation, then repo docs/smoke/commit/tag/push.

Approval token:

```text
APPROVE_STAGE_16_E3Z_H_R12_INSTALL_PVESO_RESTRICTED_MODEL_HELPER_PATH_NO_SERVICE_START
```

R12 installed a narrow CT203-to-PVESO restricted helper path without starting the scheduler service or timer.

R12 recovery R5 validated the helper path from CT203 with Python subprocess calls so the helper return code and output were deterministic.

## What R12 changed

R12 installed or reused a dedicated CT203 root-owned SSH keypair:

```text
/etc/edge-queue-controller/pveso-restricted-helper/id_ed25519
```

R12 installed a CT203 helper env file:

```text
/etc/edge-queue-controller/pveso-restricted-helper.env
```

R12 updated the CT203 scheduler environment file with helper target/key metadata while leaving scheduler delegation off.

R12 installed a PVESO root-owned forced-command helper script:

```text
/usr/local/sbin/apc-e3z-h-model-call-helper
```

R12 installed one marked PVESO `authorized_keys` block for the CT203 helper public key:

```text
APC_E3Z_H_R12_HELPER_KEY_BEGIN
APC_E3Z_H_R12_HELPER_KEY_END
```

The helper key is forced to the helper command and is not broad arbitrary shell access.

## R12 validation

R12 validated:

- CT203 helper private key mode: `600 root root`
- CT203 helper env mode: `600 root root`
- PVESO helper script mode: `755 root root`
- PVESO authorized_keys mode: `600 root root`
- PVESO helper syntax: `ok`
- CT203 to PVESO helper `--preflight-only`: `ok`
- CT203 to PVESO arbitrary command rejection: `ok`

The forced-command arbitrary command rejection proves that the installed key does not grant broad arbitrary shell access.

## Helper preflight checks

The PVESO helper `--preflight-only` command verified:

- CT101 status is stopped
- CT101 onboot is 0
- Ollama service is active
- Ollama port 11434 listener is localhost-only
- active Ollama client count is 0

R12 did not call Ollama generate/chat/embed/completion endpoints.

## Final CT203 posture

After R12:

```text
service_active=inactive
timer_active=inactive
service_enabled=static
timer_enabled=disabled
env_delegation=0
env_stat=600 root root
helper_env_stat=600 root root
helper_key_stat=600 root root
```

## DB postflight

R12 performed no DB writes.

Postflight DB state:

```text
db_integrity=ok
jobs_total=32
job_results_total=12
duplicate_job_results=0

job_23_status=queued
job_23_attempts=3
job_23_result_rows=0

job_24_status=queued
job_24_attempts=0
job_24_result_rows=0

job_33_status=queued
job_33_attempts=0
job_33_result_rows=0
job_33_type=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
job_33_model=qwen2.5:0.5b
```

## Not performed

R12 did not:

- start the scheduler service
- start the scheduler timer
- execute scheduler/wrapper
- claim job 33
- call Ollama generate/chat/embed/completion endpoints
- pull any model
- start CT101
- enable persistent workers
- mutate Cloudflare/DNS/tunnels/private storage
- grant broad arbitrary SSH from CT203 to PVESO

## Next recommended phase

Next phase:

```text
Stage 16 E3Z-H R13 — Start Service Once, Exact Job 33, Restricted PVESO Helper
```

R13 must require a new explicit approval.

R13 should:

- start the service once, not the timer
- use the restricted PVESO helper path
- claim only job 33
- call only model `qwen2.5:0.5b`
- insert exactly one result row for job 33
- complete job 33 with attempts=1/result_rows=1
- leave jobs 23 and 24 untouched
- finalize service/timer inactive and delegation=0
- commit closure only if DB-observed completion succeeds

## Hard no-rerun rules

Do not retry or rerun:

- E3V-Q
- job 29
- job 30
- job 31
- job 32

Job 33 remains eligible only because R12 did not claim it. Once job 33 is claimed or completed, do not rerun it.

## Persistent worker posture

Persistent workers remain blocked.

Scheduler timer activation remains blocked until the direct service proof succeeds and a fresh timer-proof job is inserted under a separate explicit approval.
