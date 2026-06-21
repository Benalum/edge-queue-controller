# Stage 16 E3O — Controlled Operator Dispatch Artifact No-Run

## Purpose

Stage 16 E3O adds the first controlled operator dispatch artifact:

- `ops/model/operator-dispatch-one-queued-job-via-pveso.sh`

This stage is no-run. It does not dispatch a job, call PVESO, call Ollama, call a model endpoint, mutate CT203 DB, start services, activate scheduler dispatch, or activate persistent workers.

## Baseline

E3N completed at commit `8d845ab` with tag:

- `controller-stage-16-e3n-controlled-operator-dispatch-design-no-apply-2026-06-21`

E3N documented the design contract for a controlled operator dispatch path that wraps the proven E3M manual helper primitive while keeping scheduler and persistent workers default-off.

## Artifact behavior in E3O

The E3O artifact supports safe local modes only:

- `--help`
- `--contract`
- `--plan-only`

The artifact also accepts `--execute-approved`, but execution is intentionally disabled in E3O. It exits with:

- `E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED`

This prevents accidental job execution before the next approved runtime phase.

## Future approval marker

The future execution approval marker is recorded but not acted on in E3O:

- `APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION`

Even with that marker present, E3O still refuses execution.

## Safety boundaries

E3O preserves these boundaries:

- No DB write.
- No production job mutation.
- No helper execution.
- No adapter execution.
- No model endpoint call.
- No scheduler activation.
- No persistent worker activation.
- No service lifecycle mutation.
- No CT/VM lifecycle mutation.
- No Cloudflare, DNS, tunnel, or nginx mutation.
- No private storage mutation.
- No CT101 start.
- No public PVESO or Ollama exposure.

## Required future preflight

A later approved execution phase must verify:

- CT203 DB integrity is ok.
- Target job exists.
- Target job status is queued.
- Target job has zero `job_results` rows.
- Target job requested model is allowlisted.
- Scheduler is not active.
- Persistent workers are not active.
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or false.
- PVESO Ollama is active.
- PVESO Ollama is bound only to `127.0.0.1:11434`.
- PVESO non-localhost 11434 listener count is zero.
- PVESO runner process count is zero before start.
- CT101 is stopped and onboot=0.

## Required future durable artifacts

A later approved execution phase must create durable artifacts before model work starts:

- `run_dir`
- `preflight.json`
- `adapter.stdout.txt`
- `adapter.stderr.txt`
- `model_response.txt` or `response.json`
- `db_preflight.json`
- `db_postflight.json`
- `recovery_hint.txt`
- `final_status.txt`

## Timeout recovery contract

A later approved execution phase must classify timeouts before any rerun:

- DB completed with one result row: do not rerun.
- DB queued with zero result rows and no runner: rerun only with explicit approval.
- DB queued with zero result rows and runner active: do not rerun; classify later.
- DB completed with multiple result rows: duplicate-result failure.
- DB error state: preserve artifacts and require a recovery plan.

## Duplicate result guard

A later approved execution phase must refuse to run if the target job has any existing result row.

After completion it must verify:

- Exactly one result row exists for the target job.
- The job status is completed.
- The response text is non-empty.
- Error is null.
- Any required phase marker is present.

## Public boundary

The browser must not call PVESO or Ollama directly.

The public API must not expose a raw Ollama endpoint.

The frontend must receive model output only after CT203 records durable DB results.

## Definition of done

E3O is complete when:

- The operator dispatch artifact exists.
- The artifact has a disabled execution branch.
- The artifact prints the controlled dispatch contract.
- The artifact can produce a no-run plan for one job ID.
- The smoke test verifies static safety boundaries.
- The repo is committed, tagged, pushed, and clean.
