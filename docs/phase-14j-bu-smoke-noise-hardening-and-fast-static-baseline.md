# Phase 14J-BU - Smoke Noise Hardening and Fast Static Baseline

PHASE_14J_BU_SMOKE_NOISE_HARDENING_AND_FAST_STATIC_BASELINE

Date: 2026-06-16

## Scope

MUTATION_SCOPE=smoke_docs_only_static_workflow_hardening

This phase improves the speed and quality of the safe static workflow created in BR, BS, and BT.

This phase is not runtime activation.

## Problem fixed

STATIC_INVENTORY_NOISE=cleanup_archive_paths_removed

Earlier static inventory output included historical backup/archive paths from cleanup directories. That made logs large and slowed review.

BU hardens recent static inventory smokes so they exclude cleanup archive and backup directories.

## Added artifacts

BU_ARTIFACTS_ADDED=three

1. `ops/smoke/check-phase-14j-bu-no-cleanup-archive-static-inventory-output.sh`
2. `ops/smoke/check-phase-14j-safe-static-fast-baseline.sh`
3. `docs/phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.md`

## Patched smoke behavior

PATCHED_STATIC_SMOKE_EXCLUDES=cleanup_archive_and_backups

Recent BR/BS/BT static inventory smokes now exclude cleanup archive and backup directories where applicable.

## Fast baseline

SAFE_STATIC_FAST_BASELINE_SMOKE=created

The fast baseline is intended for frequent safe-batch checks.

The full baseline remains available for deeper validation.

## Source refresh cadence

SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate

Uploaded Source refresh remains deferred until milestone, handoff, new chat, or runtime activation gate.

TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source

## Safe batch rule

SAFE_BATCH_MODE=enabled

PARALLELIZE_SAFE_GREEN_WORK  
SERIALIZE_RUNTIME_CHANGES

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

## Runtime approval boundary

ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL

Runtime activation remains blocked unless explicitly approved in a future bounded phase.

## Next phase

NEXT_SAFE_PHASE=phase_14j_bv_controller_owned_static_ui_patch_batch

Phase 14J-BV should use the fast baseline to safely perform a larger controller-owned static UI/docs patch batch.

## Patched files

```text
PATCHED_STATIC_SMOKE_EXCLUDES=cleanup_archive_and_backups
patched=ops/smoke/check-phase-14j-br-public-product-surface-static-inventory.sh
patched=ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh
patched=ops/smoke/check-phase-14j-br-source-cadence-and-ppb-contract.sh
patched=ops/smoke/check-phase-14j-bs-public-route-ownership-static-contract.sh
patched=ops/smoke/check-phase-14j-bs-product-ui-static-contract.sh
```

## No-cleanup-archive output guard evidence

```text
=== Phase 14J-BU smoke: no cleanup archive static inventory output ===
MUTATION_SCOPE=read_only_static_output_guard
NO runtime activation
NO CT101 call
NO model/Ollama endpoint call
NO DB mutation
NO job mutation

=== run public/product inventory with archive-noise guard ===
PASS: public/product inventory excludes cleanup archive paths

=== run product UI inventory with archive-noise guard ===
PASS: product UI inventory excludes cleanup archive paths

=== run route inventory with archive-noise guard ===
PASS: route inventory excludes cleanup archive paths

PASS: no cleanup archive static inventory output guard passed
```

## Fast baseline evidence

```text
=== Phase 14J safe static fast baseline smoke ===
MUTATION_SCOPE=read_only_static_fast_baseline
NO CT101 call
NO model/Ollama endpoint call
NO DB mutation
NO job mutation
NO service restart/reload
NO scheduler activation
NO worker activation
NO runtime activation

=== fast baseline: ops/smoke/check-phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint.sh ===
=== Phase 14J-BL smoke: read-only activation-surface result checkpoint ===
PASS: exists docs/phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint.md
PASS: exists ops/smoke/check-phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint.sh

=== doc markers ===
PASS: doc marker found: PHASE_14J_BL_RESULT_CHECKPOINT
PASS: doc marker found: RUNTIME_ACTIVATION=not_performed
PASS: doc marker found: SERVICE_RESTART_RELOAD=not_performed
PASS: doc marker found: CT101_MODEL_JOB_MUTATION=not_performed
PASS: doc marker found: LANE_WORKER_ENABLEMENT=not_performed
PASS: doc marker found: SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
PASS: doc marker found: PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
PASS: doc marker found: ROUTER_MODEL_SELECTION_ACTIVATION=not_performed
PASS: doc marker found: _phase14j_default_off_worker_registration_metadata
PASS: doc marker found: _phase14j_worker_eligible_for_job
PASS: doc marker found: _phase14j_filter_workers_for_lane
PASS: doc marker found: Activation remains blocked

=== source helper markers ===
PASS: source marker found: def _phase14j_lane_workers_enabled
PASS: source marker found: def _phase14j_default_off_worker_registration_metadata
PASS: source marker found: def _phase14j_job_lane_metadata
PASS: source marker found: def _phase14j_worker_lane_metadata
PASS: source marker found: def _phase14j_worker_eligible_for_job
PASS: source marker found: def _phase14j_filter_workers_for_lane
PASS: source marker found: phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()
PASS: source marker found: workers = _phase14j_filter_workers_for_lane(workers, job)

=== python compile ===
PASS: edge_controller.py compiles

=== helper behavior static verification ===
PASS: Phase 14J helper behavior markers verified

=== SQLite read-only default-off verification ===
quick_check=ok
PASS: canonical 8 worker lane metadata columns present
disabled_reason_present=no; not canonical/required
worker_count=0
lane_enabled_worker_count=0
non_default_worker_lane_count=0
non_primary_worker_role_count=0
PASS: DB worker metadata remains default-off

=== persistent lane worker flag guard ===
shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
PASS: shell persistent lane worker flag absent/disabled
PASS: service persistent lane worker flag absent

=== no runtime activation confirmation ===
RUNTIME_ACTIVATION=not_performed
SERVICE_RESTART_RELOAD=not_performed
CT101_MODEL_JOB_MUTATION=not_performed
JOB_MUTATION=not_performed
LANE_WORKER_ENABLEMENT=not_performed
SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
ROUTER_MODEL_SELECTION_ACTIVATION=not_performed

PASS: Phase 14J-BL result checkpoint smoke passed

=== fast baseline: ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh ===
=== Phase 14J-BR reusable smoke: runtime-parked surface static contracts ===
MUTATION_SCOPE=read_only_static_contracts
NO service restart/reload
NO DB mutation
NO job mutation
NO CT101 call
NO model/Ollama endpoint call
NO scheduler activation
NO worker activation
NO runtime activation
PASS: edge_controller.py compiles

=== lane activation source markers ===
PASS: marker present: def _phase14j_lane_workers_enabled
PASS: marker present: def _phase14j_default_off_worker_registration_metadata
PASS: marker present: def _phase14j_job_lane_metadata
PASS: marker present: def _phase14j_worker_lane_metadata
PASS: marker present: def _phase14j_worker_eligible_for_job
PASS: marker present: def _phase14j_filter_workers_for_lane
PASS: marker present: phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()
PASS: marker present: workers = _phase14j_filter_workers_for_lane(workers, job)
PASS: marker present: registration_metadata = _phase14j_default_off_worker_registration_metadata()
PASS: marker present: "reason_code": "lane_gate_disabled"

=== parked router/warmup/model risk markers, static only ===
router_warmup_static_hits=10919
PASS: router/warmup/model surface counted statically only

=== SQLite read-only quick_check and worker default-off ===
quick_check=ok
worker_count=0
lane_enabled_worker_count=0
non_default_worker_lane_count=0
non_primary_worker_role_count=0

=== persistent lane worker flag guard ===
shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
PASS: shell persistent lane worker flag absent/disabled
service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
PASS: service persistent lane worker flag absent

PASS: runtime-parked static contracts remain default-off

=== fast baseline: ops/smoke/check-phase-14j-br-source-cadence-and-ppb-contract.sh ===
=== Phase 14J-BR reusable smoke: Source cadence and PPB contract ===
MUTATION_SCOPE=read_only_policy_contract
NO runtime activation

=== BQ cadence and batching markers ===
PASS: BQ marker present: SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate
PASS: BQ marker present: TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source
PASS: BQ marker present: SAFE_BATCH_MODE=enabled_for_green_and_guarded_source_phases
PASS: BQ marker present: PARALLELIZE_SAFE_GREEN_WORK
PASS: BQ marker present: SERIALIZE_RUNTIME_CHANGES
PASS: BQ marker present: ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL

=== PPB policy markers in docs/source text ===
ppb_policy_marker_hits=8

=== PPB destructive action reminder ===
PPB must not be used for remote branch deletion, force local branch deletion, repository deletion, API deletion calls, metadata-directory removal, or repository-directory removal.

PASS: Source cadence and PPB policy contract smoke passed

=== fast baseline: ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh ===
=== Phase 14J-BS reusable smoke: parked runtime no-touch contract ===
MUTATION_SCOPE=read_only_safety_contract
NO service restart/reload
NO DB mutation
NO job mutation
NO CT101 call
NO model/Ollama endpoint call
NO scheduler activation
NO worker activation
NO runtime activation
PASS: edge_controller.py compiles

=== key default-off source markers ===
PASS: source marker present: def _phase14j_lane_workers_enabled
PASS: source marker present: def _phase14j_default_off_worker_registration_metadata
PASS: source marker present: def _phase14j_filter_workers_for_lane
PASS: source marker present: phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()
PASS: source marker present: workers = _phase14j_filter_workers_for_lane(workers, job)
PASS: source marker present: "reason_code": "lane_gate_disabled"

=== SQLite read-only DB guard ===
quick_check=ok
worker_count=0
lane_enabled_worker_count=0
non_default_worker_lane_count=0
non_primary_worker_role_count=0

=== persistent lane worker environment guard ===
shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
PASS: shell persistent lane worker flag absent/disabled
service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
PASS: service persistent lane worker flag absent

PASS: parked runtime no-touch contract completed

=== fast baseline: ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh ===
=== Phase 14J-BT smoke: controller-owned route and UI ownership map ===
PASS: route/UI ownership marker found: PHASE_14J_BT_CONTROLLER_OWNED_ROUTE_AND_UI_OWNERSHIP_MAP
PASS: route/UI ownership marker found: MUTATION_SCOPE=docs_smoke_only_static_contracts
PASS: route/UI ownership marker found: CONTROLLER_OWNED_SURFACES=static_public_controller_routes
PASS: route/UI ownership marker found: PROXY_OR_APP_SURFACES=protected_runtime_or_ct101_boundaries
PASS: route/UI ownership marker found: SAFE_UI_PATCH_RULE=controller_owned_static_only
PASS: route/UI ownership marker found: RUNTIME_ACTIVATION=not_performed
PASS: route/UI ownership marker found: SERVICE_RESTART_RELOAD=not_performed
PASS: route/UI ownership marker found: CT101_MODEL_OLLAMA_CALLS=forbidden
PASS: route/UI ownership marker found: DB_MUTATION=not_performed
PASS: route/UI ownership marker found: JOB_MUTATION=not_performed
PASS: route/UI ownership marker found: LANE_WORKER_ENABLEMENT=not_performed
PASS: route/UI ownership marker found: SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
PASS: route/UI ownership marker found: PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
PASS: route/UI ownership marker found: ROUTER_MODEL_SELECTION_ACTIVATION=not_performed
PASS: route/UI ownership marker found: WARMUP_EXECUTION_ACTIVATION=not_performed
PASS: route/UI ownership marker found: DO_NOT_RERUN_14J_AG_APPLY_WRAPPER
PASS: route/UI ownership marker found: ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL
PASS: controller-owned route and UI ownership map smoke passed

=== fast baseline: ops/smoke/check-phase-14j-bu-no-cleanup-archive-static-inventory-output.sh ===
=== Phase 14J-BU smoke: no cleanup archive static inventory output ===
MUTATION_SCOPE=read_only_static_output_guard
NO runtime activation
NO CT101 call
NO model/Ollama endpoint call
NO DB mutation
NO job mutation

=== run public/product inventory with archive-noise guard ===
PASS: public/product inventory excludes cleanup archive paths

=== run product UI inventory with archive-noise guard ===
PASS: product UI inventory excludes cleanup archive paths

=== run route inventory with archive-noise guard ===
PASS: route inventory excludes cleanup archive paths

PASS: no cleanup archive static inventory output guard passed

PASS: Phase 14J safe static fast baseline smoke passed
```
