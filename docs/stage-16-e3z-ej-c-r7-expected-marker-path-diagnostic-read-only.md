# Stage 16 E3Z-EJ-C-R7 — Expected Marker Path Diagnostic — Read Only

## Purpose

Diagnose the R6 failure without rerunning job 48 or mutating live state.

R6 failed with:

```text
REFUSE_EXPECTED_MARKER_NOT_FOUND
```

This is different from the earlier exact output mismatch. It indicates the worker did not find the expected marker through the path it uses before completing the job.

## Scope

This phase was read-only for live state:

- no CT203 DB mutation
- no model call
- no job insert
- no job claim
- no job complete
- no job fail
- no worker start
- no worker enable
- no worker unmask
- no scheduler/timer activation
- no Docker/model data mutation

## DB marker-path summary

```text
db_integrity=ok
jobs_status_running=1
jobs_status_queued=2
jobs_status_failed=3
jobs_status_completed=21
jobs_total=47
job_results_total=27
jobs_max_id=48
job_48_status=running
job_48_attempts=2
job_48_requested_model=qwen2.5:0.5b
job_48_job_type=stage16_e3z_limited_persistent_worker_repeat_proof
job_48_result_rows=0
job_48_prompt_sha256=06a508e24928649dd0e8d4f5431b2f4d75dcf09f631586078a2bdf28d4b9d043
```

## Worker/profile marker lookup summary

```text
old_worker_active=inactive
old_worker_enabled=masked
new_worker_active=inactive
new_worker_enabled=disabled
running_names=ollama
active_transients=<none>
edge_timers=<none>
unit_active=inactive
unit_state=not-found,inactive,dead
worker_sha256=69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f
profile_sha256=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
```

## Interpretation

The important decision point is whether the worker expects the marker in a structured field such as expected_marker, expected_response, payload_json, metadata_json, or profile metadata, rather than in the prompt text.

If job 48 is now running again after the failed R6 attempt, repair must first reset job 48 back to queued exactly as R4 did before any additional retry.

The next repair should be targeted to the missing expected-marker path. It should not blindly retry the same transient command.

## Recommended next step

Prepare EJ-C-R8 as a no-apply or exact DB repair plan based on this diagnostic.

Likely repair direction:

- If job 48 lacks expected_marker or expected_response columns/metadata values, add the marker only to the worker-readable structured field for job 48.
- Keep job 48 status queued if already queued, or reset stale running to queued if R6 left it running.
- Preserve attempts and result_rows unless the repair plan explicitly decides otherwise.
- Do not call a model during marker-path repair.
- Do not mutate jobs 37 through 47.
- Then run a separate approved retry only after the marker path is validated read-only.

## Guard result

```text
E3Z_EJ_C_R7_EXPECTED_MARKER_PATH_DIAGNOSTIC_READ_ONLY_OK=1
```
