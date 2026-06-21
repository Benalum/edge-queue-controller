# Stage 16 E3Z-H R11H — PVESO Restricted Model Helper Plan, No Apply

## Phase status

MUTATION_SCOPE: repo docs/smoke/commit/tag/push only.

This phase records the E3Z-H service proof blocker and defines the next safe apply boundary.

No live infrastructure was changed by this phase.

## Current state entering R11H

Repo checkpoint entering this plan:

```text
HEAD/origin/main: bc79a04
Previous installed scheduler/timer checkpoint: E3Z-G
```

CT203 unit/queue posture from R11G:

```text
service_active=inactive
timer_active=inactive
service_enabled=static
timer_enabled=disabled
env_delegation=0
env_stat=600 root root
```

DB state from R11G:

```text
db_integrity=ok
jobs_total=32
job_results_total=12
duplicate_job_results=0

job_23_status=queued
job_23_type=ollama_chat
job_23_model=gemma4:e4b
job_23_attempts=3
job_23_result_rows=0

job_24_status=queued
job_24_type=companion.chat
job_24_model=mock/no-model
job_24_attempts=0
job_24_result_rows=0

job_33_status=queued
job_33_type=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
job_33_model=qwen2.5:0.5b
job_33_attempts=0
job_33_result_rows=0
```

## What R11C proved

R11C started the CT203 scheduler service once under an explicit approval boundary.

The service and harness ran, and the CT203-runtime-safe shim reached the local DB read-only preflight:

```text
E3Z_H_R11C_WRAPPER_DB_INTEGRITY=ok
E3Z_H_R11C_WRAPPER_DUPLICATE_RESULTS=0
E3Z_H_R11C_WRAPPER_JOB_BEFORE id=33 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke result_rows=0
E3Z_H_R11C_WRAPPER_ELIGIBLE_EXACT_COUNT=1
```

R11C failed before atomic claim because CT203 could not execute the PVESO preflight through the selected Tailscale target:

```text
ssh: connect to host <redacted-tailscale-ip> port 22: No route to host
```

Therefore R11C did not claim job 33 and did not call Ollama.

## What R11D/R11E/R11F/R11G proved

R11D-Lite:

```text
E3Z_H_R11D_LITE_CT203_PVESO_FOUND=0
CT203 has no tailscale command
CT203 has no configured PVESO target
pveso and pveso.local do not resolve from CT203
```

R11E:

```text
CT203 can reach PVESO over a LAN address.
The LAN path reaches PVESO SSH.
The observed output was an inventory-style forced command, not the requested command body.
```

R11F:

```text
E3Z_H_R11F_CT203_PVESO_COMMAND_EXEC_OK=0
E3Z_H_R11F_CT203_PVESO_FORCED_COMMAND_SEEN=1
```

This means CT203 currently has a safe restricted inventory SSH path to PVESO, but not a command-capable model execution path.

R11G:

```text
E3Z_H_R11G_CT203_TO_PVEW_COMMAND_EXEC_OK=0
E3Z_H_R11G_PVEW_TO_PVESO_COMMAND_EXEC_OK=0
E3Z_H_R11G_PVEW_TO_PVESO_FORCED_COMMAND_SEEN=0
```

This rules out a PVEW-mediated helper shortcut under the current SSH/DNS/network posture.

## Decision

Do not keep retrying E3Z-H service or timer activation until CT203 has an approved, narrow, command-capable path to PVESO.

The next safe design is not broad arbitrary SSH. It is a restricted PVESO forced-command helper dedicated to one bounded model-call operation.

## Proposed next apply phase

Proposed apply phase name:

```text
Stage 16 E3Z-H R12 — Install PVESO Restricted Model Helper Path, No Service Start
```

Proposed approval token:

```text
APPROVE_STAGE_16_E3Z_H_R12_INSTALL_PVESO_RESTRICTED_MODEL_HELPER_PATH_NO_SERVICE_START
```

## R12 allowed scope

R12 should allow only:

- create one CT203-owned SSH keypair dedicated to the PVESO restricted helper path
- install only the public key on PVESO under a forced command
- install one root-owned PVESO helper script, mode 0755 or stricter
- install one CT203 private-key file, root-owned, mode 0600
- install one CT203 PVESO target/env file entry, root-owned, mode 0600
- run bounded read-only helper handshake tests that do not call Ollama
- optionally run one helper `--preflight-only` command that verifies:
  - CT101 remains stopped
  - CT101 onboot remains 0
  - Ollama service is active
  - Ollama listens only on localhost
  - active Ollama client count is 0
  - model `qwen2.5:0.5b` is present if checked through a non-generating local command

R12 must not:

- start the scheduler service
- start the scheduler timer
- claim job 33
- call Ollama generate/chat/embed/completion endpoints
- pull any model
- start CT101
- enable persistent workers
- mutate Cloudflare/DNS/tunnels/private storage
- broadly grant arbitrary SSH from CT203 to PVESO
- use GitHub branch/repo deletion

## PVESO helper guard design

PVESO helper path should be a forced command, not shell access.

Recommended forced command shape:

```text
command="/usr/local/sbin/apc-e3z-h-model-call-helper",no-agent-forwarding,no-X11-forwarding,no-pty,no-port-forwarding
```

The helper should support two subcommands:

```text
--preflight-only
--run-exact-job-33-small-model
```

R12 should install and validate only `--preflight-only`.

A later R13 or R11C-retry may use `--run-exact-job-33-small-model` under a separate service-start approval.

## PVESO helper hard checks

The helper must refuse unless all checks pass:

```text
APC_STAGE16_E3Z_H_HELPER_APPROVAL matches exact approval
requested job id is exactly 33
requested model is exactly qwen2.5:0.5b
requested job type is exactly stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
num_predict <= 8
temperature == 0
timeout <= 35 seconds
CT101 status is stopped
CT101 onboot is 0
Ollama service is active
Ollama 11434 listener is localhost only
active model client/runner count is 0 before call
```

For R12, the helper must not call `/api/generate`, `/api/chat`, `/api/embed`, or any other model execution endpoint.

## Follow-on proof after R12

After R12 installs and validates the restricted helper path without model calls, a later explicit activation phase can retry the direct service proof:

```text
Stage 16 E3Z-H R13 — Start Service Once, Exact Job 33, Restricted PVESO Helper
```

R13 must still:

- start the service once, not the timer
- claim job 33 only after all preflights pass
- call only model `qwen2.5:0.5b`
- insert exactly one job result for job 33
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

Job 33 may be used only by the next exact-job proof because it is still queued with attempts=0/result_rows=0 as of R11G. Once job 33 is claimed or completed, do not rerun it.

## Persistent worker posture

Persistent workers remain blocked.

Scheduler timer activation remains blocked.

Timer proof should wait until:

1. direct service proof succeeds through the restricted helper path, and
2. a fresh timer-proof job is inserted under a separate explicit approval.
