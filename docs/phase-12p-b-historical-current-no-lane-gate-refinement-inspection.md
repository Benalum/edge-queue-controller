# Phase 12P-B Historical-vs-Current No-Lane Gate Refinement Inspection

Phase 12P-B inspected how the read-only persistent lane cutover gate should distinguish historical no-lane evidence from current no-lane risk.

## Result

The inspection completed safely.

No services were changed.
No jobs were inserted.
No queue rows were mutated.
No routing behavior changed.
No workers were restarted.
No persistent lane cutover was enabled.

## Current gate behavior before refinement

The current `persistent_lane_cutover_readiness` gate is live and reports:

- `source=stage_5p12o_read_only_persistent_lane_cutover_gate`
- `dry_run_only=true`
- `ready=false`

Current reasons include:

- `primary_worker_unfiltered`
- `historical_no_lane_jobs_detected`
- `persistent_lane_workers_not_active`
- `no_no_lane_fallback_worker`

The phrase below is intentionally exact for smoke validation:

historical_no_lane_jobs_detected is currently a permanent blocker.

## Current active job risk

Inspection found no active unsupported/no-lane jobs.

Specifically, there were no queued, pending, running, claimed, processing, or in-progress `ollama_chat` `app_jobs` with:

- missing `queue_lane`
- unsupported `queue_lane`

This means there is no current active no-lane queue risk at the time of inspection.

## Historical no-lane evidence

Historical no-lane `app_jobs` rows still exist.

They include old completed or failed `gemma4:e4b` jobs from:

- `stage_5h2_real_user_mode_aware_creation_helper`
- `stage_5f18_real_user_creation_helper`
- older rows with missing route source

These rows are useful evidence, but they should not permanently block future readiness by themselves.

## Lane-tagged evidence

Recent lane-tagged `app_jobs` rows exist, including:

- `phase12l-tiny-job-7ddc80a044438855`
- `phase12m-small-job-e8ec453de2951427`
- `s5f18-job-c57e61463dfd7e39`

These prove that the current real-user `app_jobs` helper can create Stage 5P11R lane-tagged jobs.

## Recommended refinement

The next code patch should refine `persistent_lane_cutover_readiness` as follows:

- Move old no-lane rows into an evidence section.
- Keep historical no-lane evidence visible.
- Stop treating old completed/failed historical no-lane rows as a permanent blocker by themselves.
- Continue treating active unsupported/no-lane jobs as blockers.
- Add a blocker for `recent_no_lane_jobs_after_lane_contract` only when no-lane rows were created after Stage 5P11R lane-tagged jobs began.
- Keep current blockers for:
  - `primary_worker_unfiltered`
  - `persistent_lane_workers_not_active`
  - `no_no_lane_fallback_worker`

The exact future blocker name is:

recent_no_lane_jobs_after_lane_contract

## Expected state after future refinement

After the future refinement, `ready` should still be false because:

- primary worker is still unfiltered
- persistent lane workers are not active
- no no-lane fallback worker exists

But `historical_no_lane_jobs_detected` should move from `reasons` into evidence when the only no-lane rows are old completed/failed history.

## Safety state

This phase was inspection/documentation only.

Runtime remains unchanged:

- primary worker active
- tiny lane worker inactive
- small lane worker inactive
- tiny/small services disabled
- no active queued/running jobs
- router rollout parked
