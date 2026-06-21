# Stage 16 E3R — Claim/Lease Scheduler Dry-Run No-Apply Plan

## Purpose

E3R converts the E3Q scheduler-integration design into an implementation plan for a default-off scheduler dry-run path.

This phase is no-apply.

## Starting baseline

The current proven path is:

```text
CT203 queued job
→ operator dispatch artifact
→ manual helper
→ PVESO one-shot adapter
→ localhost-only Ollama on PVESO
→ CT203 DB completionRun with Project Pilot
Running...

E3Q defined the scheduler-ready target:

CT203 queued job
→ scheduler claim/lease gate
→ controlled dispatch contract
→ PVESO one-shot adapter
→ localhost-only Ollama on PVESO
→ CT203 DB completion
E3R output target

E3R plans two later artifacts:

A scheduler dry-run selector that can identify one eligible queued job without writing to the DB.
A claim/lease data-shape plan for a later explicit DB schema/apply phase.

E3R does not implement automatic claiming, scheduling, model calls, or DB writes.

Dry-run selector behavior

The future dry-run selector should:

read CT203 DB in read-only mode
list eligible queued jobs
verify zero existing result rows
verify requested model is allowlisted
verify lane is known
verify scheduler activation flag is disabled
print the job it would claim
print the dispatch command it would run
refuse unknown lanes
refuse already completed jobs
refuse jobs with result rows
refuse non-allowlisted models

Dry-run output must include a NO_DB_WRITE marker.

Candidate claim/lease data shape

A later DB schema phase may add a durable claim table or equivalent fields.

Candidate claim fields:

claim_id
job_id
claim_state
claim_actor
claim_lane
requested_model
dispatch_contract
claimed_at
lease_expires_at
completed_at
failed_at
recovery_status
dispatch_run_dir
last_error

E3R does not apply this schema.

Lease rules

A later runtime phase must enforce:

exactly one active claim per job
lease expiration before retry
no retry if a runner is active
no retry if the job already has a result row
read-only timeout classification before recovery
durable run directory before model execution
exactly one final status per claim
Activation boundary

A later explicit approval is required before:

DB schema apply
DB claim/lease write
scheduler service start or enable
persistent worker start or enable
lane worker activation
automatic job claim
helper execution
adapter execution
model call
job completion
job result insert
Safety invariants

E3R preserves:

scheduler off
persistent workers off
CT101 stopped/onboot=0
PVESO Ollama localhost-only
no public model exposure
no model pull/download
no rerun of job 27
no mutation of jobs 25, 26, or 27
Recommended next phases
E3S: implement scheduler dry-run artifact, no DB writes.
E3T: insert one fresh scheduler-test queued job, explicit approval.
E3U: run one scheduler-controlled dispatch smoke, explicit approval.
