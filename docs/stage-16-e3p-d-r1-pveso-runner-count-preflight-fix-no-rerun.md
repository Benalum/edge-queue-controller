# Stage 16 E3P-D-R1 — PVESO Runner Count Preflight Fix No-Rerun

## Purpose

Stage 16 E3P-D-R1 fixes the controlled operator dispatch artifact after the first E3P-D execution attempt failed before model/helper execution.

The failure occurred during PVESO preflight. Job 27 remained queued with zero result rows, so no model/DB completion occurred and no rerun was performed in this recovery phase.

## Root cause

The operator artifact counted Ollama runner processes using a `grep | wc -l` pipeline inside command substitution while `set -euo pipefail` was active.

When zero runners existed, `grep` returned exit code 1. Zero runners is the expected safe state, but `pipefail` caused the preflight to fail before helper/adapter/model execution.

## Scope

Allowed in this phase:

- Read-only CT203 DB classification for job 27.
- Read-only PVESO runner/listener/CT101 classification.
- Read-only inspection of the failed run directory.
- Patch the operator artifact runner counting to use `awk` counters that return `0` safely.
- Add this recovery document and smoke.
- Commit, tag, and push.

Denied in this phase:

- No DB write.
- No job completion.
- No `job_results` insert.
- No helper execution.
- No adapter execution.
- No operator dispatch execution.
- No model endpoint call.
- No scheduler activation.
- No persistent worker activation.
- No CT101 start.
- No public PVESO/Ollama exposure.

## Preserved runtime state

Read-only classification confirmed:

- Job 27 status: `queued`
- Job 27 attempts: `0`
- Job 27 result rows: `0`
- Total jobs: `26`
- Total job_results: `8`
- Worker count: `2`
- DB integrity: `ok`
- PVESO Ollama active: yes
- PVESO Ollama localhost-only: yes
- PVESO runner count: `0`
- CT101 stopped/onboot=0: yes

## Failed run directory

The failed E3P-D attempt printed this run directory before failing:

`/home/alex/.local/share/apc-operator-dispatch-runs/stage-16-e3p-d/job-27-20260621T165822Z`

The failure was before dispatch stdout/stderr from helper execution because the PVESO preflight returned nonzero first.

## Patch

The operator artifact now uses `awk` for runner and serve process counts so a zero-runner state is represented as numeric `0` instead of a failed pipeline.

## Next step

E3P-D may be retried against job 27 only after explicit approval remains in effect or is re-confirmed by the operator.

Before retrying, verify again that job 27 is queued with zero result rows and PVESO runner count is zero.

Do not rerun against jobs 25 or 26.
