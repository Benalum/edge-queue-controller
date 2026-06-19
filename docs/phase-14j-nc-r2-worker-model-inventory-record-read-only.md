# Phase 14J-NC-R2 — Worker/Model Inventory Record Read-Only

Updated: 2026-06-18

## Status

COMPLETED READ-ONLY INVENTORY.

This phase did not wake PVESO, start workers, activate models, call model endpoints, enable scheduler dispatch, enable worker lanes/filters, start or stop CTs/VMs, restart services, unlock private storage, mount private storage, create backups, restore databases, change CT204 authority, change Cloudflare/DNS/tunnels, or print secrets/env contents.

## Baseline

- Previous checkpoint: Phase 14J-NB worker/model re-entry procedure plan no-apply.
- Previous commit: `ae07a10`.
- Previous tag: `controller-phase-14j-nb-worker-model-reentry-procedure-plan-no-apply-2026-06-18`.
- Repo state before this phase: clean.

## Public baseline

- public_status_http_code: `200`
- overall_state: `online`
- schema_version: `2`
- node_ids_sorted: `ct-203,ct-204,pvew,vm-200`
- private_storage_policy: `manual-unlock-only`
- private_storage_mount_state_public: `unknown`
- private_storage_mountpoint_public: `/srv/apc-private-data`
- ct204_expected_state: `stopped`
- ct204_data_authority: `false`
- public_app_src: `/app.js?v=2026061814jlbr2`
- public_app_sha256: `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- public_app_legacy_hits: absent

## PVEW and storage baseline

- ct203_status: `running`
- ct204_status: `stopped`
- vm200_status: `running`
- private_storage_mount_state_host: `not_mounted`
- private_storage_mapper_state: `absent`
- private_storage_crypt_status: `inactive`

## CT203 service baseline

- edge_queue_controller_service_active: `active`
- edge_queue_controller_service_enabled: `enabled`

## CT203 SQLite inventory

- sqlite_integrity_check: `ok`
- sqlite_table_count: `40`
- worker_queue_model_related_tables: `job_results,jobs,worker_events,workers`
- table_count_workers: `2`
- table_count_jobs: `22`
- table_count_worker_events: `3`
- table_count_job_results: `6`

## Worker table inventory

- workers_columns: `worker_id,name,host_id,target_name,status,capabilities_json,current_jobs,max_concurrent_jobs,queue_depth,cpu_percent,ram_total_mb,ram_free_mb,gpu_name,vram_total_mb,vram_free_mb,consecutive_failures,restart_attempts,last_error,first_seen_at,last_heartbeat_at,updated_at,worker_role,worker_lane,accepts_lane_jobs,capabilities,disabled,current_running_jobs,state,computed_health`
- workers_status_counts: `offline:2`
- workers_health_counts: `offline:2`
- workers_lane_counts: `primary:1,study:1`
- workers_accepts_lane_jobs_counts: `0:1,1:1`

## Jobs table inventory

- jobs_status_counts: `failed:1,forwarded:20,queued:1`
- jobs_type_counts: `ollama_chat:22`

## Interpretation

Worker/model re-entry remains blocked behind staged approvals.

The current DB has a workers table and lane-related metadata columns including:

- `worker_role`
- `worker_lane`
- `accepts_lane_jobs`
- `capabilities`
- `disabled`
- `current_running_jobs`
- `state`
- `computed_health`

The related tables found are `job_results`, `jobs`, `worker_events`, and `workers`.

No evidence in this phase approves or performs worker activation, model endpoint calls, scheduler dispatch activation, PVESO wake/start, or real user traffic routing.

## Next safe options

1. Phase 14J-ND — PVESO wake/start plan no-apply.
2. Source refresh/new-chat handoff.
3. Phase 14J-MY private storage reopen apply only if explicitly approved later.
4. Phase 14J-NA CT204 restore drill only after private storage reopen and explicit approval.

## Result

RESULT=PASS_PHASE_14J_NC_R2_WORKER_MODEL_INVENTORY_RECORD_READ_ONLY_DONE
