# Stage 16 E3Z-Q — Scheduler Artifact Allowlist Update Plan, No Activation

STAGE_16_E3Z_Q_PLAN=1
NO_ACTIVATION=1
PROOF_JOB_ALLOWLIST=35,36
HARD_NO_RERUN=E3V-Q,29,30,31,32,33,34

## Purpose

This document records the no-activation plan for moving from the completed E3Z-N proof-job insertion and E3Z-O/R4 read-only process classification into a controlled scheduler artifact update.

The plan exists because the current CT203 scheduler runtime artifacts were originally built for the earlier exact job 33 direct-service proof. Jobs 35 and 36 are now the fresh queued proof jobs for the controlled periodic timer path. Before any timer/service activation, the scheduler artifacts must be updated so the live scheduler can only consider jobs 35 and 36 and must refuse all older queued or completed/failed proof jobs.

## Current verified posture before this plan

- Repository checkpoint before E3Z-Q: `ea9225a`.
- Previous tag: `controller-stage-16-e3z-m-controlled-periodic-timer-activation-plan-no-apply-2026-06-21`.
- CT203 authoritative DB path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- E3Z-N inserted two fresh queued proof jobs:
  - job 35: marker `E3Z-N-A-OK`, status queued, attempts 0, requested_model `qwen2.5:0.5b`, result rows 0.
  - job 36: marker `E3Z-N-B-OK`, status queued, attempts 0, requested_model `qwen2.5:0.5b`, result rows 0.
- E3Z-O/R4 classified the scheduler process concern as false-positive/transient:
  - real scheduler process count 0.
  - timer inactive/disabled.
  - scheduler service inactive/static.

## Required future artifact behavior

Any future live artifact update must make the scheduler proof path exact and allowlist-based:

- Allowed proof job IDs: `35,36` only.
- Allowed model: `qwen2.5:0.5b` only.
- Allowed job type: `stage16_e3z_i_timer_proof_after_direct_service_small_model_completion_smoke` only.
- One job per tick remains required.
- Max jobs per tick remains 1.
- Persistent lane workers remain disabled.
- Delegation/model execution remains disabled by default unless an explicitly approved one-tick or bounded timer proof enables it for the exact proof run.
- Old queued jobs 23 and 24 must not be claimable by this proof path.
- Hard no-rerun items must remain excluded: E3V-Q, jobs 29, 30, 31, 32, 33, and 34.

## Required future stage sequence

1. E3Z-R should perform the scheduler artifact allowlist update with explicit approval, but still no timer activation and no model call. It may update the CT203 scheduler tick/dispatch artifacts so they can accept exact proof jobs 35 and 36. If unit-file content changes, systemd reload must be explicitly included in that approval boundary.
2. E3Z-S should run a read-only post-artifact pre-activation guard proving the artifacts now allow only jobs 35 and 36, timer is inactive/disabled, and no scheduler process is running.
3. E3Z-T should require separate explicit approval for any timer/service activation. The activation should be bounded, observable, and designed to process at most one proof job per tick.
4. E3Z-U should run read-only closure/idle guard after any activation proof.

## Non-goals for this stage

This E3Z-Q stage does not update CT203 live files, does not update the DB, does not claim jobs, does not start services, does not start or enable timers, does not reload systemd, does not enable helper run mode, does not call PVESO/Ollama, and does not activate persistent workers or broad scheduler dispatch.
