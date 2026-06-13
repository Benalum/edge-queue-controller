# Phase 12P-A No-Lane Production Job Creation Path Inspection

Phase 12P-A inspected which job creation paths can create no-lane work before any persistent lane worker cutover.

## Result

The inspection completed safely.

No services were changed.
No jobs were inserted.
No queue rows were mutated.
No routing behavior changed.
No workers were restarted.

## Current safety state

At inspection time:

- Controller was healthy.
- Persistent cutover gate was live.
- Persistent cutover gate reported `ready=false`.
- No active queued/running `ollama_chat` jobs existed.
- Primary CT101 worker was active.
- Tiny lane worker was inactive.
- Small lane worker was inactive.
- Tiny and small lane services remained disabled.
- Router rollout remained parked.

## Important correction

The direct public helper `_public_create_ollama_job()` writes to the local `jobs` table, not the Postgres `app_jobs` table used by the CT101 laptop queue worker.

That means it should not be treated as the same persistent lane cutover path without a separate bridge/mapping decision.

## app_jobs lane status

The current real-user queued chat helper path in `edge_modules/chat_queue_real_user_creation.py` includes Stage 5P11R lane metadata:

- `routing_contract_version`
- `routing_decision`
- `model_tier`
- `model_lane`
- `queue_lane`
- `model_max_parallel_hint`

Recent lane-tagged `app_jobs` rows exist, including:

- `phase12l-tiny-job-7ddc80a044438855`
- `phase12m-small-job-e8ec453de2951427`
- `s5f18-job-c57e61463dfd7e39`

## Historical no-lane evidence

Historical no-lane `app_jobs` rows still exist, including older `gemma4:e4b` jobs from:

- `stage_5h2_real_user_mode_aware_creation_helper`
- `stage_5f18_real_user_creation_helper`
- older rows with missing route source

These rows are historical completed/failed rows, but they prove the system previously created no-lane `app_jobs`.

## Synthetic queued helper risk

The synthetic queued helper in `edge_modules/chat_queue_creation.py` creates test/synthetic `app_jobs` payloads and does not currently include the full lane contract.

That helper is synthetic/test-only, but it should not be ignored when designing a permanent no-lane prevention rule.

## Recommended next phase

Do not immediately patch `_public_create_ollama_job()` as though it is the CT101 `app_jobs` path.

Instead, add a Phase 12P-B source-map/guard refinement that separates:

- local direct public `jobs` table work
- Postgres `app_jobs` CT101 worker queue work
- synthetic/test `app_jobs`
- real-user production `app_jobs`

Then refine the readiness gate so it can distinguish historical no-lane rows from active/recent no-lane production risk.

## Smoke-required wording

The direct public helper uses the local jobs table.

The CT101 worker queue uses Postgres app_jobs.

Do not immediately patch _public_create_ollama_job as though it is the CT101 app_jobs lane path.
