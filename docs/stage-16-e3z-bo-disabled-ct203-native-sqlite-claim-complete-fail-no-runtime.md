# Stage 16 E3Z-BO — Disabled CT203 Native SQLite Claim/Complete/Fail Implementation

## Result

Implemented the CT203-native SQLite worker API behind the existing disabled flag:

EDGE_CT203_SQLITE_WORKER_API_ENABLED=0

No runtime deployment or service restart is performed by this stage.

## SQLite schema contract used

The implementation uses only the current CT203 SQLite schema:

- jobs.id
- jobs.job_type
- jobs.prompt
- jobs.requested_model
- jobs.status
- jobs.attempts
- jobs.last_error
- jobs.created_at
- jobs.updated_at
- jobs.forwarded_at
- jobs.user_id
- job_results.job_id
- job_results.model
- job_results.response_text
- job_results.response_json
- job_results.error
- job_results.created_at
- job_results.updated_at
- worker_events

It does not require worker registry tables because they do not exist in the CT203 SQLite DB.

## Claim behavior

POST /internal/edge-worker/jobs/claim now:

- requires the feature flag and token
- requires exact claim_job_ids
- refuses retired proof jobs 29 through 34
- uses BEGIN IMMEDIATE
- claims only status queued
- updates status to running
- increments attempts
- updates updated_at
- returns the claimed job
- inserts a worker event if worker_events exists

## Completion behavior

POST /internal/edge-worker/jobs/{job_id}/complete now:

- requires the feature flag and token
- requires the job to be running
- refuses duplicate job_results
- inserts one result row
- updates job status to completed
- updates updated_at
- inserts a worker event if worker_events exists

## Failure behavior

POST /internal/edge-worker/jobs/{job_id}/fail now:

- requires the feature flag and token
- requires the job to be running
- updates job status to failed
- writes last_error
- updates updated_at
- inserts a worker event if worker_events exists

## Runtime posture

The implementation remains dormant until a separately approved deploy/restart and flag-enable stage.

This stage does not start CT101 worker service, Docker, Ollama, scheduler, or timer.
