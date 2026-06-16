# Phase 14J-CH - Gate A Controller-Side Lane Flag Activation and Rollback Evidence

PHASE_14J_CH_GATE_A_CONTROLLER_SIDE_LANE_FLAG_ACTIVATION_AND_ROLLBACK_EVIDENCE

## Scope

MUTATION_SCOPE=bounded_runtime_service_env_activation_and_rollback
APPROVED_RUNTIME_SCOPE=edge_queue_controller_service_env_only

Phase 14J-CH temporarily enabled `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1` for `edge-queue-controller.service`, restarted only that service, verified the bounded Gate A activation state, then intentionally rolled back to default-off.

## Explicit non-goals preserved

- DB_MUTATION=not_performed_by_phase
- JOB_MUTATION=not_performed_by_phase
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- ROUTER_ROLLOUT=not_performed
- WARMUP_EXECUTION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved

## Runtime evidence

```text
PHASE_14J_CH_RUNTIME_ONLY_GATE_A_EVIDENCE
DROPIN_FILE=/etc/systemd/system/edge-queue-controller.service.d/phase-14j-ch-gate-a-lane-flag.conf
service_active_before=active
service_enabled_before=enabled
service_flag_before=<unset>
shell_flag_before=<unset>
db_quick_before=ok
worker_counts_before=0,0,0,0
jobs_before="failed:1,forwarded:20,queued:1"
RUNTIME_GATE_TEMPORARILY_ACTIVATED=yes
service_active_activation=active
service_flag_activation=EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1
db_quick_activation=ok
worker_counts_activation=0,0,0,0
jobs_activation="failed:1,forwarded:20,queued:1"
ROLLBACK_PERFORMED=yes
service_active_final=active
service_enabled_final=enabled
service_flag_final=<unset>
db_quick_final=ok
worker_counts_final=0,0,0,0
jobs_final="failed:1,forwarded:20,queued:1"
FINAL_STATE_DEFAULT_OFF=yes
RUNTIME_ACTIVATION_LEFT_ENABLED=no
```

## Commit-time verification

- service_active_at_commit=active
- service_flag_at_commit=<unset>
- sqlite_quick_check_at_commit=ok
- lane_enabled_worker_count_at_commit=0

## Result

- RUNTIME_GATE_TEMPORARILY_ACTIVATED=yes
- ACTIVATION_SMOKE=passed
- ROLLBACK_PERFORMED=yes
- ROLLBACK_SMOKE=passed
- FINAL_STATE_DEFAULT_OFF=yes
- RUNTIME_ACTIVATION_LEFT_ENABLED=no

Phase 14J-CH proved the controller-side service env flag can be enabled and rolled back in a bounded Gate A test.

NEXT_SAFE_PHASE=decide_whether_to_leave_gate_a_enabled_or_prepare_gate_b_worker_availability
