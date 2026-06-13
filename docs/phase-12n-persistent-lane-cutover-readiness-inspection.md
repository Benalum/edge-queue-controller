# Phase 12N Persistent Lane Cutover Readiness Inspection

Phase 12N inspected whether CT101 is ready to permanently cut over from the unfiltered primary worker to persistent lane workers.

## Current proven lane status

The controlled lane tests have passed:

- `model-tiny` worker completed a `qwen3:0.6b` job.
- `model-small` worker completed a `qwen3:1.7b` job.

This proves:

- The lane-worker systemd template works.
- Per-lane env overrides work.
- Worker registration metadata works.
- Queue-lane claim filtering works.
- Tiny and small model execution paths work.

## Current runtime state

Inspection confirmed:

- Primary worker service is active.
- Primary worker is unfiltered.
- Tiny lane service is inactive.
- Small lane service is inactive.
- Tiny and small services are disabled.
- No active queued/running `ollama_chat` jobs existed.
- Router rollout remains parked.

## Key cutover risk

Persistent lane cutover is not ready yet.

Reason:

- The primary worker is still unfiltered.
- Historical no-lane jobs exist.
- Future no-lane jobs could be stranded if the primary worker is stopped and only lane-filtered workers are running.

## Historical no-lane evidence

Inspection found historical no-lane `ollama_chat` jobs, including:

- `gemma4:e4b` jobs from `stage_5h2_real_user_mode_aware_creation_helper`
- `gemma4:e4b` jobs from `stage_5f18_real_user_creation_helper`
- older no-lane jobs with missing route source

These jobs were completed or failed in the past, but they prove that production paths have created no-lane jobs before.

## Cutover options

### Option A: Start tiny+small lanes while primary remains active

Unsafe.

The primary worker is unfiltered and could steal lane-tagged jobs.

### Option B: Stop primary and run only tiny+small lanes

Unsafe unless every future production job is guaranteed to include a supported `queue_lane`.

Any no-lane job would remain queued.

### Option C: Add a no-lane fallback worker

Possible, but requires explicit design.

Current claim filter supports exact `queue_lane` equality. A no-lane fallback would require a safe claim mode for jobs where `payload_json->>'queue_lane'` is missing or empty.

### Option D: Convert all production job creation to lane-tag every job

Preferred before permanent cutover.

All new production jobs should have a supported queue lane before the primary worker is permanently replaced by lane-filtered workers.

## Recommended next phase

Add a read-only persistent cutover readiness gate.

The gate should report:

- `ready=false` if primary worker is unfiltered and lane workers are requested.
- `ready=false` if active jobs include unsupported or missing queue lanes.
- `ready=false` if recent production job creation can still create no-lane jobs.
- `ready=false` if no no-lane fallback worker exists and no-lane jobs are possible.
- `ready=true` only when all active/new jobs are lane-routable or a fallback worker exists.

## Safety state

This phase was inspection/documentation only.

No services were started.
No services were stopped.
No jobs were inserted.
No routing behavior changed.
No persistent lane cutover was enabled.
