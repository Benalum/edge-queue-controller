# Stage 16 E3N — Controlled Operator Dispatch Design No-Apply

## Purpose

Stage 16 E3N designs a controlled operator dispatch path that wraps the proven manual helper primitive from Stage 16 E3M without turning on scheduler dispatch or persistent workers.

E3M proved that an explicitly approved operator helper can complete one queued DB job through PVESO Ollama. E3N does not run the helper. E3N does not call a model. E3N records the next design layer needed before the project can safely move from manual helper proof toward a controlled dispatch artifact.

## Baseline evidence before this design

The new-chat E3N preflight baseline confirmed:

- Repository HEAD and origin were at c8c5d78.
- The E3M-B2-R3 tag existed.
- The working tree was clean.
- Public routes were healthy.
- CT203 was running, onboot=1, service active/enabled, listener 7070 present.
- CT203 DB integrity was ok.
- Counts matched the handoff: user_sessions=236, jobs=25, job_results=8, workers=2, worker_events=3.
- Job 25 was completed with attempts=1 and one result row.
- Job 26 was completed with attempts=1 and one result row.
- Job 26 response_text was APC_E3M_B2_OK.
- Job 26 result contained APC_STAGE16_E3M_B2_MANUAL_HELPER_COMPLETION_RESULT.
- EDGE_PERSISTENT_LANE_WORKERS_ENABLED was absent.
- Worker metadata rows were offline/default-off.
- PVESO Ollama was active, version 0.15.4, localhost-only on 127.0.0.1:11434.
- PVESO had no non-localhost 11434 listener.
- PVESO had one ollama serve process and zero runner processes.
- CT101 was stopped and onboot=0.

## Hard non-goals

E3N is no-apply design only.

Denied in this phase:

- No DB mutation.
- No production job mutation.
- No scheduler activation.
- No persistent worker activation.
- No worker service start or enable.
- No model endpoint call.
- No model pull or download.
- No CT101 start.
- No CT or VM lifecycle mutation.
- No service lifecycle mutation.
- No Cloudflare, DNS, tunnel, or nginx mutation.
- No private storage unlock, mount, format, key, crypttab, or fstab mutation.
- No public exposure of PVESO or Ollama.
- No browser or public API path may call PVESO or Ollama directly.

## Proposed operator dispatch concept

The controlled operator dispatch path should be a narrow, explicit, default-off entrypoint.

Candidate future artifact name:

- ops/model/operator-dispatch-one-queued-job-via-pveso.sh

The artifact should not be a scheduler and should not be a persistent worker. It should be an operator tool that dispatches one specific queued job by ID after strong preflight checks.

The desired flow is:

1. Operator provides an explicit job ID.
2. Tool performs CT203 read-only DB preflight for that job.
3. Tool confirms the job is queued and has zero result rows.
4. Tool confirms requested model is allowlisted.
5. Tool confirms PVESO Ollama is active, localhost-only, and has no existing runner for this project path.
6. Tool creates a durable local run directory before model execution begins.
7. Tool records job ID, model, timestamps, and command boundaries in status artifacts.
8. Tool invokes the existing adapter/helper primitive only after preflight passes and explicit phase approval exists.
9. Tool writes model output to a durable artifact before any DB completion step.
10. Tool completes the DB lifecycle exactly once.
11. Tool performs read-only postflight classification.
12. Tool prints a compact final status suitable for PPB copy/paste.

## Required interface

Future operator dispatch should require:

- job_id: required integer.
- expected_status: default queued.
- expected_result_rows: default 0.
- requested_model: optional assertion; if provided, it must match the DB job.
- max_runtime_seconds: explicit bound or documented default.
- run_root: durable local or remote run directory.
- approval marker: explicit phase approval for any DB/model execution phase.

The tool must refuse if:

- job_id is missing.
- job does not exist.
- job is already completed.
- job has one or more result rows.
- requested model is not allowlisted.
- PVESO Ollama is not localhost-only.
- an Ollama runner is already active and cannot be classified.
- Tailscale SSH is not ready.
- CT101 is not stopped/onboot=0 when CT101 must remain protected.
- scheduler or persistent workers appear active.
- EDGE_PERSISTENT_LANE_WORKERS_ENABLED is true.

## Idempotency rules

A target job may be completed exactly once.

Preflight must require:

- jobs.id equals target job ID.
- jobs.status equals queued.
- job_results rows for target job equals zero.
- jobs.attempts is within the expected range for the phase.
- requested_model is known and allowlisted.
- no prior completion marker exists for the target job.

Postflight must verify:

- jobs.status equals completed.
- job_results rows for target job equals one.
- response_text is non-empty.
- response_json or result payload contains the expected phase marker when the test requires one.
- error is null.
- no second result row was inserted.

If a timeout occurs, rerun is denied until read-only recovery classification proves the next state.

## Timeout and recovery classification

E3M-B2 and E3M-B2-R2 proved that a PPB timeout can happen while remote model execution or DB completion continues. Therefore, timeout handling must classify state rather than assume failure.

Recovery states:

1. DB completed and one result row exists:
   - Do not rerun model work.
   - Do docs/smoke/commit recovery only.

2. DB queued, zero result rows, no PVESO runner:
   - Treat as not completed.
   - Rerun only after explicit approval and with a longer timeout or split execution plan.

3. DB queued, zero result rows, PVESO runner active:
   - Treat as in-progress or unknown.
   - Do not rerun.
   - Wait, inspect run artifacts, or classify again later.

4. DB running or forwarded with no result row:
   - Treat as ambiguous.
   - Do read-only DB and PVESO runner checks.
   - Do not duplicate model work.

5. DB completed with more than one result row:
   - Treat as duplicate-result failure.
   - Stop and investigate before any further runtime execution.

6. DB error state:
   - Preserve artifacts.
   - Do not retry automatically.
   - Require an explicit recovery plan.

## Output capture requirements

Future controlled dispatch should write durable artifacts before long model execution begins.

Required artifacts:

- run_dir path.
- preflight.json.
- command.env.allowlist.txt with non-secret allowlisted values only.
- adapter.stdout.txt.
- adapter.stderr.txt.
- model_response.txt or response.json.
- db_preflight.json.
- db_postflight.json.
- recovery_hint.txt.
- final_status.txt.

The tool must print run_dir before model execution begins. This prevents PPB timeout from hiding the path needed for recovery.

## Tailscale SSH handling

Tailscale SSH authentication can require interactive repair. If Tailscale SSH is not ready, the operator dispatch tool should fail before any model or DB mutation.

The recovery instruction should be:

- Run a direct terminal Tailscale SSH auth check outside PPB.
- Confirm hostname, Ollama active state, and CT101 state.
- Return to PPB after auth succeeds.

The dispatch artifact should not try to solve interactive auth inside a long model execution path.

## PVESO and Ollama boundary

PVESO remains on-demand model compute only.

Required boundary:

- Ollama must stay bound to 127.0.0.1:11434.
- Non-localhost 11434 listener count must be zero.
- Public frontend must not call PVESO.
- CT203 public API must not expose raw Ollama endpoints.
- Browser must receive results only from CT203 DB/API after job completion.

## Scheduler and worker boundary

Controlled operator dispatch is not scheduler activation.

E3N preserves:

- No scheduler dispatch.
- No persistent worker process.
- No worker service enablement.
- No default-on lane worker behavior.
- No autonomous loop over queued jobs.
- No multi-job batch dispatch.

The future artifact should process exactly one job ID per invocation.

## Promotion path

Recommended next phases:

- E3O: Add controlled operator dispatch artifact no-run.
- E3P: Insert one fresh synthetic queued job and run the controlled dispatch artifact with explicit approval.
- E3Q: Design default-off scheduler integration.
- E3R: First scheduler-dispatched model job, one-shot, single job, explicit approval.

Promotion to scheduler or persistent worker behavior requires additional proof and a separate explicit approval boundary.

## Definition of done for E3N

E3N is complete when:

- This design document exists.
- A focused smoke verifies the no-apply boundaries and required design topics.
- The repo is committed, tagged, pushed, and clean.
- No DB, service, CT/VM, model, worker, scheduler, Cloudflare/DNS/tunnel/nginx, or private storage mutation occurred.

## Smoke-verified design checklist

The controlled operator dispatch design includes these explicit requirements:

- Single-job dispatch by job ID.
- Guardrails against duplicate job_results rows.
- Idempotent preflight before model work.
- Durable output capture before long-running execution.
- Read-only recovery classification after timeout.
