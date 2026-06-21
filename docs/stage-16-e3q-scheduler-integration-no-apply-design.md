# Stage 16 E3Q — Scheduler Integration No-Apply Design

## Purpose

E3Q designs how the proven E3P controlled-dispatch chain becomes scheduler-ready without activating scheduler or persistent workers.

This phase is no-apply.

## Proven E3P chain

```text
CT203 queued job
→ operator dispatch artifact
→ manual helper
→ PVESO one-shot adapter
→ localhost-only Ollama on PVESO
→ CT203 DB completionRun with Project Pilot
Run with Project Pilot

E3P proved job 27 completed exactly once:

Job status: completed
Attempts: 1
Result rows: 1
Total jobs: 26
Total job_results: 9
Response text: APC_E3P_OK\nAPC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT
PVESO runner count after completion: 0
CT101: stopped, onboot=0
Scheduler-ready target
CT203 queued job
→ scheduler claim/lease gate
→ controlled dispatch contract
→ PVESO one-shot adapter
→ localhost-only Ollama on PVESO
→ CT203 DB completion

The scheduler must become a controlled caller of the proven E3P dispatch contract, not a new unbounded model-execution path.

Default-off rule

Scheduler integration remains default-off until a later explicit activation approval.

Required default-off controls:

Scheduler loop remains inactive.
Persistent lane workers remain inactive.
EDGE_PERSISTENT_LANE_WORKERS_ENABLED remains absent or false.
No queued job may be claimed automatically.
No model may be called automatically.
Claim and lease requirements

A future scheduler phase must define a durable claim/lease gate before model execution.

Minimum requirements:

Select exactly one eligible queued job.
Verify requested model is allowlisted.
Verify the job has zero existing result rows.
Verify the job is not already completed.
Verify no active lease conflict exists.
Refuse if an earlier claim is still inside its lease window.
Record actor, lane, model, claim time, and dispatch run ID.
Require timeout recovery classification before retry.

No claim/lease DB change is applied in E3Q.

Duplicate-result guard

Before any model call, the dispatch layer must refuse if the job already has a result row.

Timeout rules:

Completed with one result row: do not rerun.
Queued with zero result rows and no runner: retry requires explicit approval.
Runner active: do not rerun.
Multiple result rows: duplicate-result failure.
Ambiguous state: preserve artifacts and do not rerun.
Scheduler eligibility rules

A future scheduler-controlled dispatcher must require:

status=queued
zero existing job_results rows
requested model in allowlist
known lane mapping
no active lease conflict
PVESO reachable
Ollama active
Ollama listener localhost-only
target model present
CT101 stopped/onboot=0
no public PVESO/Ollama exposure
explicit scheduler activation flag enabled
Conservative lane/model mapping

Initial automatic dispatch should remain disabled for normal lanes.

Proposed future lanes:

operator-test: one-job scheduler smoke candidate
study: design only, not automatic yet
primary: design only, not automatic yet
unknown lanes: refuse

Initial model allowlist:

qwen2.5:32b-instruct-q4_K_M
qwen2.5-coder:32b-instruct-q4_K_M

No model pull or download is allowed during dispatch.

Activation boundary

A later activation phase must require explicit approval before any of these actions:

DB schema apply
DB claim/lease write
scheduler service start/enable
persistent worker start/enable
lane worker activation
automatic job claim
helper execution
adapter execution
model call
job completion
job result insert
Non-goals

E3Q does not:

activate scheduler
activate persistent workers
start CT101
expose PVESO/Ollama publicly
mutate Cloudflare, DNS, tunnel, or nginx
mutate private storage
call models
write DB rows
rerun job 27
Next recommended phases
E3R: claim/lease and scheduler dry-run implementation plan, no apply.
E3S: scheduler dry-run artifact, no DB writes.
E3T: insert one fresh scheduler-test queued job, explicit approval.
E3U: run one scheduler-controlled dispatch smoke, explicit approval.
