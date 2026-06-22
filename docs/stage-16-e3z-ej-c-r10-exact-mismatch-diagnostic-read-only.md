# Stage 16 E3Z-EJ-C-R10 — Exact Mismatch Diagnostic — Read Only

## Purpose

Diagnose the R9 failure without rerunning job 48 or mutating live state.

R9 got past expected-marker extraction, then failed with:

```text
REFUSE_WORKER_EXACT_MARKER_MISMATCH
```

That means the worker extracted the expected marker successfully but the model response did not exactly equal it.

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

## DB and prompt diagnostic summary

```text
db_integrity=ok
jobs_total=47
job_results_total=27
jobs_max_id=48
```

## CT101 runtime and worker diagnostic summary

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
disabled_refusal_rc=1
```

## Interpretation

R9 likely left job 48 stale running again with attempts incremented and result_rows still zero.

The marker extractor is now working, so the remaining failure is output compliance from the model path.

The safer next repair is not another same-prompt retry. The next plan should either:

1. reset job 48 to queued and change the prompt to a known-good legacy wording patterned after job 47, or
2. add a worker-side normalization/diagnostic improvement in repo before any further live retry, or
3. retire job 48 and create a new replacement proof job with a prompt known to work.

Because job 47 completed with qwen2.5 using the one-job limited persistent path, the preferred next step is a no-apply repair plan comparing job 47 prompt style and then a separate approved reset/prompt repair.

## Guard result

```text
E3Z_EJ_C_R10_EXACT_MISMATCH_DIAGNOSTIC_READ_ONLY_OK=1
```
