# Phase 14J-BO - Read-Only Runtime Rollback Evidence Plan

PHASE_14J_BO_READ_ONLY_RUNTIME_ROLLBACK_EVIDENCE_PLAN

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_runtime_read_only_evidence

This phase records rollback evidence and rollback planning for a future lane-worker runtime activation phase.

This phase is not runtime activation.

## Non-activation confirmations

RUNTIME_ACTIVATION=not_performed  
SERVICE_RESTART_RELOAD=not_performed  
CT101_MODEL_OLLAMA_CALLS=forbidden  
CT101_MODEL_JOB_MUTATION=not_performed  
DB_MUTATION=not_performed  
JOB_MUTATION=not_performed  
LANE_WORKER_ENABLEMENT=not_performed  
SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed  
PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed  
ROUTER_MODEL_SELECTION_ACTIVATION=not_performed  
WARMUP_EXECUTION_ACTIVATION=not_performed  

DO_NOT_RERUN_14J_AG_APPLY_WRAPPER

## Current decision

ACTIVATION_DECISION=still_blocked_pending_explicit_approval

Persistent lane worker runtime activation remains blocked.

EDGE_PERSISTENT_LANE_WORKERS_ENABLED=must_remain_absent_or_disabled

## Rollback objective

ROLLBACK_OBJECTIVE=return_to_primary_default_behavior

If a later approved activation phase enables persistent lane workers and causes a failure, rollback must restore the pre-activation default behavior:

- persistent lane worker gate disabled
- scheduler lane dispatch disabled
- primary/default worker behavior preserved
- no primary-worker filtering left active
- no CT101/model/Ollama/job/DB mutation required for rollback verification
- rollback verification smokes pass

## Trusted source behavior supporting rollback

The current trusted Phase 14J activation surface is:

- `_phase14j_lane_workers_enabled`
- `_phase14j_default_off_worker_registration_metadata`
- `_phase14j_job_lane_metadata`
- `_phase14j_worker_lane_metadata`
- `_phase14j_worker_eligible_for_job`
- `_phase14j_filter_workers_for_lane`

Important rollback behavior:

- `_phase14j_lane_workers_enabled()` reads `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`.
- Scheduler filtering remains gated by `phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()`.
- Scheduler filtering call remains `workers = _phase14j_filter_workers_for_lane(workers, job)`.
- When the lane gate is disabled, `_phase14j_filter_workers_for_lane(workers, job)` preserves the original worker list.
- Worker registration uses `_phase14j_default_off_worker_registration_metadata()`.
- Disabled-gate evidence marker remains `"reason_code": "lane_gate_disabled"`.

## Planned rollback command path

ROLLBACK_COMMAND_PATH=planned_not_executed

The rollback command path is documented here for a future explicitly approved rollback phase only.

These commands are not executed in Phase 14J-BO.

Planned rollback actions for a future approved phase:

1. Disable or remove `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` from the service environment.
2. Reload systemd only if the approved rollback phase changes systemd configuration.
3. Restart or reload `edge-queue-controller` only if the approved rollback phase explicitly permits it.
4. Re-run rollback verification smoke.
5. Confirm the persistent lane worker gate is absent/disabled in shell and service.
6. Confirm worker/default-off counts remain safe.
7. Confirm BL/BN/BO smokes pass.
8. Confirm scheduler primary/default behavior is preserved.

SERVICE_RESTART_RELOAD_REQUIRED_FOR_ACTUAL_ROLLBACK=approval_required_later

## Rollback verification requirements

ROLLBACK_VERIFICATION_SMOKE=defined

A future activation phase cannot be considered rollback-ready unless it can verify:

1. Repo is clean.
2. `HEAD == origin/main`.
3. SQLite read-only `PRAGMA quick_check` returns `ok`.
4. Canonical worker lane metadata columns are present.
5. `disabled_reason` remains non-canonical and not required.
6. Worker/default-off counts are expected and safe.
7. `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent/disabled after rollback.
8. BL smoke passes.
9. BN smoke passes.
10. BO smoke passes.
11. Any later activation smoke has a matching rollback smoke.
12. No CT101/model/Ollama/job/DB mutation is needed to confirm rollback.

## Current blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `runtime_activation_approval_required`
- `rollback_runtime_evidence_pending_until_activation_rehearsal`

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_bp_read_only_activation_go_no_go_readiness_review

Phase 14J-BP should be a read-only go/no-go readiness review.

It should decide whether the project has enough evidence to ask for a later explicit, bounded runtime activation approval.

Phase 14J-BP should not activate runtime by default.

## Explicit approval boundary

ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL

A future runtime activation phase requires explicit user approval.

Without explicit approval, the following remain blocked:

- enabling persistent lane workers
- scheduler lane dispatch activation
- primary-worker filtering activation
- service reload/restart
- CT101/model/Ollama calls
- production job mutation
- DB mutation
- router rollout
- warmup execution

## Read-only evidence captured during Phase 14J-BO

- Repository checkpoint before BO: `7fba6f4`
- Service name inspected: `edge-queue-controller`
- service_load_state: `loaded`
- service_active_state: `active`
- service_sub_state: `running`
- service_fragment_path: `/etc/systemd/system/edge-queue-controller.service`
- service_dropins: `/etc/systemd/system/edge-queue-controller.service.d/10-direct-ollama-forward.conf /etc/systemd/system/edge-queue-controller.service.d/10-power-idle.conf /etc/systemd/system/edge-queue-controller.service.d/100-wake-and-start.conf /etc/systemd/system/edge-queue-controller.service.d/110-power-auto-start.conf /etc/systemd/system/edge-queue-controller.service.d/120-direct-ollama-forward.conf /etc/systemd/system/edge-queue-controller.service.d/130-tick-direct-mode.conf /etc/systemd/system/edge-queue-controller.service.d/140-public-api.conf /etc/systemd/system/edge-queue-controller.service.d/145-admin-emails.conf /etc/systemd/system/edge-queue-controller.service.d/165-local-mock-ad-rewards.conf /etc/systemd/system/edge-queue-controller.service.d/170-web-power-policy.conf /etc/systemd/system/edge-queue-controller.service.d/175-pveso-tailscale-host.conf /etc/systemd/system/edge-queue-controller.service.d/180-ct101-idle-policy.conf /etc/systemd/system/edge-queue-controller.service.d/185-queued-chat-real-user-smoke.conf /etc/systemd/system/edge-queue-controller.service.d/186-trusted-wrapper-secret-for-queued-chat.conf /etc/systemd/system/edge-queue-controller.service.d/20-proxmox-inventory.conf /etc/systemd/system/edge-queue-controller.service.d/20-public-api.conf /etc/systemd/system/edge-queue-controller.service.d/30-power-stop-plan.conf /etc/systemd/system/edge-queue-controller.service.d/30-rewarded-ads-pending.conf /etc/systemd/system/edge-queue-controller.service.d/40-email-verification-smtp.conf /etc/systemd/system/edge-queue-controller.service.d/40-power-execute.conf /etc/systemd/system/edge-queue-controller.service.d/50-host-wake.conf /etc/systemd/system/edge-queue-controller.service.d/60-host-shutdown.conf /etc/systemd/system/edge-queue-controller.service.d/70-power-auto.conf /etc/systemd/system/edge-queue-controller.service.d/80-power-auto-pause.conf /etc/systemd/system/edge-queue-controller.service.d/90-power-auto-safe-start.conf /etc/systemd/system/edge-queue-controller.service.d/90-worker-start.conf /etc/systemd/system/edge-queue-controller.service.d/91-power-auto-full.conf /etc/systemd/system/edge-queue-controller.service.d/95-current-proxmox-power-inventory.conf /etc/systemd/system/edge-queue-controller.service.d/95-worker-start-execute.conf /etc/systemd/system/edge-queue-controller.service.d/99-power-auto-safe-runtime.conf /etc/systemd/system/edge-queue-controller.service.d/override.conf /etc/systemd/system/edge-queue-controller.service.d/power-auto.conf /etc/systemd/system/edge-queue-controller.service.d/zz-production-guarded-power.conf /etc/systemd/system/edge-queue-controller.service.d/zzz-power-auto-safe-runtime.conf`
- shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED: `<unset>`
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED: `<unset>`

This evidence was captured with read-only `systemctl show` calls. No service reload, restart, runtime activation, CT101 call, model call, job mutation, or DB mutation was performed.
