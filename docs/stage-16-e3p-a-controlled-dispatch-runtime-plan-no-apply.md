# Stage 16 E3P-A — Controlled Dispatch Runtime Plan No-Apply

## Purpose

Stage 16 E3P-A defines the runtime plan for the first controlled operator dispatch execution, but does not execute it.

E3P is the first phase family that will eventually cross back into DB/model runtime. Therefore this plan splits the work into small approval-gated steps instead of combining job insertion, artifact patching, model execution, and DB completion in one high-risk bundle.

## Current checkpoint

E3O completed with:

- Commit: `c053839`
- Tag: `controller-stage-16-e3o-controlled-operator-dispatch-artifact-no-run-2026-06-21`
- Working tree: clean at handoff
- Artifact added: `ops/model/operator-dispatch-one-queued-job-via-pveso.sh`
- Artifact state: no-run; execution intentionally disabled

## E3P-A scope

Allowed in E3P-A:

- Write this runtime plan document.
- Write a focused smoke for this runtime plan.
- Run source/static checks.
- Commit, tag, and push.

Denied in E3P-A:

- No DB write.
- No synthetic job insertion.
- No production job mutation.
- No helper execution.
- No adapter execution.
- No operator dispatch execution.
- No model endpoint call.
- No PVESO/Ollama generate/chat/embed/prompt/completion call.
- No scheduler activation.
- No persistent worker activation.
- No service lifecycle mutation.
- No CT/VM lifecycle mutation.
- No CT101 start.
- No Cloudflare, DNS, tunnel, nginx, or public route mutation.
- No private storage mutation.

## Recommended E3P split

### E3P-B — Add execution-capable operator dispatch implementation no-run

Goal: patch `ops/model/operator-dispatch-one-queued-job-via-pveso.sh` so it contains the real execution path, but keep the phase no-run.

E3P-B remains source-only:

- No DB write.
- No model call.
- No helper execution.
- No adapter execution.
- No synthetic job insertion.
- No CT203 mutation.
- No PVESO runtime call.

E3P-B should add implementation for:

- CT203 read-only DB preflight.
- Scheduler/persistent worker default-off check.
- PVESO read-only Ollama/runner check.
- CT101 stopped/onboot=0 check.
- Durable run directory creation before long execution.
- Adapter/helper invocation wrapper for a later approved phase.
- DB postflight classification.
- Timeout recovery hints.
- Duplicate-result refusal.

E3P-B smoke must prove:

- `--execute-approved` refuses without the exact approval marker.
- `--dry-run` or `--plan-only` does not contact CT203 or PVESO.
- The script references the correct helper and adapter paths.
- The script writes or plans durable artifacts.
- The script contains duplicate `job_results` protection.
- The script contains timeout recovery classification.
- The script does not enable scheduler or persistent workers.

### E3P-C — Insert one fresh synthetic queued job only

Goal: insert exactly one new synthetic queued job into CT203 DB for the operator dispatch test.

E3P-C is a real DB mutation and requires explicit approval.

Required approval phrase:

`APPROVE_STAGE_16_E3P_C_INSERT_ONE_SYNTHETIC_OPERATOR_DISPATCH_JOB_ONLY`

E3P-C must:

- Run DB integrity before insert.
- Record pre-insert counts.
- Insert one job with a new job ID.
- Use job type `stage16_e3p_operator_dispatch_synthetic_model_smoke`.
- Use requested model `qwen2.5:32b-instruct-q4_K_M`.
- Use a prompt that expects deterministic response text `APC_E3P_OK`.
- Include marker `APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT`.
- Confirm only one new job row was inserted.
- Confirm no `job_results` row exists for the new job.
- Confirm scheduler and persistent workers remain off.
- Commit/tag only documentation or smoke evidence if source files changed.

E3P-C must not:

- Call PVESO.
- Call Ollama.
- Execute the helper.
- Execute the adapter.
- Complete the job.
- Start scheduler or workers.

### E3P-D — Execute controlled operator dispatch for one queued job

Goal: run the E3P-B operator dispatch artifact against the fresh E3P-C job ID.

E3P-D is a real model call and DB lifecycle mutation and requires explicit approval.

Required approval phrase:

`APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION`

E3P-D must:

- Target exactly one job ID.
- Refuse unless the target job is queued.
- Refuse unless the target job has zero result rows.
- Refuse unless the requested model is allowlisted.
- Confirm CT203 DB integrity before execution.
- Confirm scheduler and persistent workers are off.
- Confirm `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or false.
- Confirm PVESO Ollama is active.
- Confirm PVESO Ollama is localhost-only on `127.0.0.1:11434`.
- Confirm non-localhost 11434 listener count is zero.
- Confirm PVESO runner count is zero before execution.
- Confirm CT101 is stopped/onboot=0.
- Print `run_dir` before model execution begins.
- Save model/adapter output into durable artifacts.
- Insert exactly one `job_results` row.
- Update exactly one `jobs` row to completed.
- Confirm response text `APC_E3P_OK`.
- Confirm marker `APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT`.
- Confirm no duplicate result row.
- Confirm no runner remains active after completion.

E3P-D must not:

- Loop over multiple jobs.
- Enable scheduler.
- Enable persistent workers.
- Expose PVESO/Ollama publicly.
- Start CT101.
- Retry automatically after timeout.

## Timeout recovery policy for E3P-D

If PPB times out during E3P-D, do not rerun immediately.

Required recovery sequence:

1. Run CT203 DB read-only classification for the target job.
2. Run PVESO runner/process read-only classification.
3. Classify state:

   - Completed with exactly one result row: do not rerun; document recovery.
   - Queued with zero result rows and no runner: rerun only with explicit approval.
   - Queued with zero result rows and runner active: do not rerun; classify later.
   - Completed with more than one result row: duplicate-result failure.
   - Error state: preserve artifacts and write a recovery plan.

## Fresh job rule

Never rerun E3P runtime against jobs 25 or 26.

E3P must use a fresh queued job ID created specifically for the E3P operator dispatch test.

## Public boundary

The public route remains:

Frontend -> CT203 API -> DB job -> controlled operator dispatch -> PVESO local Ollama -> CT203 DB result -> frontend polling/display.

The browser must never call PVESO or Ollama directly.

CT203 must not expose a raw public Ollama endpoint.

## Current recommendation

Proceed next with E3P-B:

- Patch the operator dispatch artifact to contain the execution-capable path.
- Keep execution disabled during E3P-B.
- Run only static/source smokes.
- Commit/tag/push.
- Then request explicit approval for E3P-C DB insertion.
