# Phase 14J-BQ - Parallel Safe Workstream Plan and Static Surface Inventory

PHASE_14J_BQ_PARALLEL_SAFE_WORKSTREAM_PLAN_AND_STATIC_SURFACE_INVENTORY

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_static_inventory

This phase records the project speed-up policy and performs a static multi-surface inventory so later work can proceed in safer batches.

This phase is not runtime activation.

## Source refresh cadence decision

SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate

Uploaded Project Source files should not be regenerated after every small docs/smoke phase.

Use this cadence instead:

1. Continue within the same chat using terminal output as the latest source of truth.
2. Refresh uploaded Source files at significant milestone/handoff points.
3. Refresh uploaded Source files before opening a new chat when the browser becomes slow.
4. Refresh uploaded Source files before any explicit runtime activation approval gate.
5. Refresh uploaded Source files after a major architecture decision or safety rule change that would be unsafe to keep only in terminal history.

TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source

## Safe batching policy

SAFE_BATCH_MODE=enabled_for_green_and_guarded_source_phases

Parallelize safe work:

- read-only inspections
- static code discovery
- docs-only records
- smoke-only artifacts
- independent default-off code paths
- independent UI/static polish
- regression smoke chains
- commit/tag/push after explicit phase intent and passing validation

Do not batch risky runtime work:

- service restart/reload
- DB mutation
- job mutation
- CT101/model/Ollama calls
- scheduler activation
- worker activation
- persistent lane worker enablement
- primary-worker filtering activation
- router rollout activation
- warmup execution activation

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

## Current checkpoint entering BQ

- Previous checkpoint: Phase 14J-BP
- Previous commit: `44e5bea`
- Previous tag: `controller-phase-14j-bp-read-only-activation-go-no-go-readiness-review-2026-06-16`
- BP decision: `GO_NO_GO_DECISION=go_for_approval_request_only`
- Runtime activation: not approved and not performed

## Parallel workstreams

### Workstream A - Lane worker activation safety

Status: guarded / approval-required.

Allowed now:

- docs/smoke-only planning
- rollback verification docs
- static source inspection

Not allowed now:

- enabling `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- service reload/restart
- scheduler lane dispatch activation
- primary-worker filtering activation

### Workstream B - Scheduler and primary-worker filtering

Status: static/read-only until explicit approval.

Allowed now:

- inspect scheduler code paths
- add disabled/default-off tests
- document fallback and defer behavior

Not allowed now:

- live scheduler behavior change
- primary/default worker filtering activation

### Workstream C - Router and warmup

Status: parked.

Allowed now:

- static inspection
- disabled/default-off docs/smoke
- model selection plan without activation

Not allowed now:

- live model/Ollama calls
- router rollout activation
- warmup execution

### Workstream D - Study and Companion product polish

Status: best candidate for parallel non-runtime progress.

Allowed next:

- static inspection
- UI copy/layout improvements
- read-only smoke coverage
- backend API static contract checks
- default-off feature flags

Guardrails:

- no CT101 calls
- no model calls
- no production job mutation
- no queue/runtime behavior mutation unless separately approved

### Workstream E - Profile, Account, Credits, Admin, System

Status: good candidate for safe parallel inspection and selected low-risk polish.

Allowed next:

- static route/API inventory
- docs/smoke coverage
- controller-owned UI/static improvements
- account/profile/credits contract checks

Guardrails:

- no secrets exposure
- no auth bypass
- no billing/credit ledger mutation unless explicitly approved and tested

### Workstream F - Calendar

Status: provider-backed direction preserved.

Allowed next:

- Google/Apple provider-backed planning
- UI placeholder polish
- static contract docs/smoke

Not allowed:

- custom/local calendar event DB storage
- provider credential handling without explicit design

### Workstream G - PPB / developer acceleration

Status: usable for guarded operational work.

Allowed next:

- PPB green/read-only tasks
- docs/smoke/source phase bundles with explicit phase intent

Never allowed:

- GitHub branch/repository deletion
- destructive repository removal
- runtime activation bypass

## Next execution strategy

NEXT_EXECUTION_STRATEGY=batch_safe_independent_workstreams

Recommended next phase:

NEXT_SAFE_PHASE=phase_14j_br_batched_static_contract_inventory_and_first_safe_patch_candidates

Phase 14J-BR should use the BQ inventory to identify the first batch of safe, independent code/doc/smoke patches outside runtime activation.

Preferred BR candidates:

1. Study/Companion/Profile/Admin/System static route inventory.
2. Controller-owned UI polish that does not touch runtime.
3. Read-only smoke coverage for public route ownership.
4. Default-off contract tests for parked router/warmup behavior.
5. Docs/smoke consolidation for the next larger milestone.

## Runtime approval boundary

ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL

A future activation phase still requires explicit user approval.

Without that approval, runtime activation remains blocked.

## Read-only evidence captured during Phase 14J-BQ

- quick_check: `ok`
- worker_count: `0`
- lane_enabled_worker_count: `0`
- non_default_worker_lane_count: `0`
- non_primary_worker_role_count: `0`
- shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED: `<unset>`
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED: `<unset>`

## Static surface inventory counts

- study_files: `1165`
- companion_files: `1131`
- calendar_files: `583`
- credits_files: `502`
- profile_files: `760`
- admin_system_files: `1793`
- scheduler_worker_files: `1317`
- router_warmup_files: `1297`
- ppb_files: `1`

This inventory was static/read-only. It did not call CT101, Ollama, model endpoints, production jobs, or mutate the database.

### Top static files for Study

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/index.js.bak-ad-status-route-2026-06-05-122025
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/index.js.bak-google-gpt-client-claim-2026-06-05-123400
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/app.js.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/index.js.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/index.js.bak-password-reset-2026-06-05-143339
```

### Top static files for Companion

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cgpt-bridge/validate.sh
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/index.js.bak-ad-status-route-2026-06-05-122025
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/index.js.bak-google-gpt-client-claim-2026-06-05-123400
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/app.js.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/index.js.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
```

### Top static files for Calendar

```text
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/app.js.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/public_gateway.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-144035/app.js.bak-password-reset-ui-2026-06-05-143929
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-144035/index.html.bak-password-reset-ui-2026-06-05-143929
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-144035/index.html.bak-password-reset-ui-2026-06-05-143929.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-145222/app.js.bak-system-labels-2026-06-05-145123
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-145222/index.html.bak-system-labels-2026-06-05-145123
```

### Top static files for Credits

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/rewarded_ads.py.bak-match-ad-count-original-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/rewarded_ads.py.bak-extract-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/rewarded_ads.py.bak-extract-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/rewarded_ads.py.bak-extract-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/rewarded_ads.py.bak-extract-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/check-rewarded-ad-claim-behavior.sh.bak-legacy-sync-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/rewarded_ads.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/credits.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/credits.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/rewarded_ads.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/rewarded_ads.py.bak-ad-provider-config-2026-06-05-121956
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123146/check-rewarded-ad-claim-behavior.sh.bak-client-claim-guard-2026-06-05-123059
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123146/rewarded_ads.py.bak-client-claim-guard-2026-06-05-123059
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/.env.example.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
```

### Top static files for Profile Account

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/index.html.bak-fix-register-verification-response-2026-06-05-132223.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-135639/email_verification.py.bak-api-verify-email-link-2026-06-05-135347
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/app.js.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/email_verification.py.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/index.html.bak-frontend-verify-redirect-2026-06-05-142049.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/email_verification.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/public_gateway.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143816/email_verification.py.bak-token-minutes-2026-06-05-143712
```

### Top static files for Admin System

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cgpt-bridge/reports/baseline-validation-20260607-100951.log
.cgpt-bridge/validate.sh
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/rewarded_ads.py.bak-extract-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/rewarded_ads.py.bak-extract-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/rewarded_ads.py.bak-extract-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/rewarded_ads.py.bak-extract-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/check-rewarded-ad-claim-behavior.sh.bak-legacy-sync-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/rewarded_ads.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/credits.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/credits.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/rewarded_ads.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/index.js.bak-ad-status-route-2026-06-05-122025
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/rewarded_ads.py.bak-ad-provider-config-2026-06-05-121956
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/index.html.bak-google-gpt-rewarded-ui-2026-06-05-122617.bak-bump-app-version-20260609200419
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123146/check-rewarded-ad-claim-behavior.sh.bak-client-claim-guard-2026-06-05-123059
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123146/rewarded_ads.py.bak-client-claim-guard-2026-06-05-123059
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/index.js.bak-google-gpt-client-claim-2026-06-05-123400
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.html.bak-email-verification-ui-2026-06-05-131606
```

### Top static files for Scheduler Worker Lane

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cgpt-bridge/reports/baseline-validation-20260607-100951.log
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/.env.example.bak-ad-provider-config-2026-06-05-122011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/index.js.bak-ad-status-route-2026-06-05-122025
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/index.js.bak-google-gpt-client-claim-2026-06-05-123400
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/.env.example.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/index.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/index.js.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/.env.example.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/index.js.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/public_gateway.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143816/.env.example.bak-token-minutes-2026-06-05-143712
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-account-roles-credits-2026-06-04-124356
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-public-api-2026-06-03-103919
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-public-api-2026-06-03-103919.bak-gemma4-e4b-2026-06-03-180022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-reset-endpoint-2026-06-02-111517
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-reset-endpoint-2026-06-02-111517.bak-gemma4-e4b-2026-06-03-180022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-admin-support-panel-2026-06-04-161839
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-ad-reward-dev-guard-2026-06-04-145354
```

### Top static files for Router Warmup

```text
.cgpt-bridge/reports/baseline-validation-20260607-100754.log
.cleanup-archive/2026-06-10-155808/audits/audits/project-cleanup-audit-2026-06-10-154949.txt
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-101856/edge_controller.py.bak-extract-ad-reward-basic-2026-06-05-101747
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-102048/edge_controller.py.bak-ad-count-nowiso-2026-06-05-102022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-103211/edge_controller.py.bak-extract-ad-reward-status-2026-06-05-103031
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112857
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-113908/edge_controller.py.bak-extract-ad-reward-init-tables-2026-06-05-112928
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115134/edge_controller.py.bak-extract-ad-reward-claim-2026-06-05-115101
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-115402/edge_controller.py.bak-fix-ad-claim-extraction-2026-06-05-115213
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120404/edge_controller.py.bak-extract-credit-pool-small-helpers-2026-06-05-120311
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-120824/edge_controller.py.bak-extract-credit-grants-2026-06-05-120742
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-121118/edge_controller.py.bak-ad-claim-use-credit-helper-2026-06-05-121011
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122727/app.js.bak-google-gpt-rewarded-ui-2026-06-05-122617
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/app.js.bak-google-gpt-client-claim-2026-06-05-123359
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131246/edge_controller.py.bak-email-verification-backend-2026-06-05-130750
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-131730/app.js.bak-email-verification-ui-2026-06-05-131606
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-132314/app.js.bak-fix-register-verification-response-2026-06-05-132223
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-134453/edge_controller.py.bak-api-auth-verify-email-alias-2026-06-05-134228
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-142307/app.js.bak-frontend-verify-redirect-2026-06-05-142049
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/edge_controller.py.bak-change-password-2026-06-05-142944
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/edge_controller.py.bak-password-reset-2026-06-05-143339
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-144035/app.js.bak-password-reset-ui-2026-06-05-143929
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-145222/app.js.bak-system-labels-2026-06-05-145123
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-account-roles-credits-2026-06-04-124356
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-public-api-2026-06-03-103919
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-public-api-2026-06-03-103919.bak-gemma4-e4b-2026-06-03-180022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-reset-endpoint-2026-06-02-111517
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-add-reset-endpoint-2026-06-02-111517.bak-gemma4-e4b-2026-06-03-180022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-admin-support-panel-2026-06-04-161839
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-ad-reward-dev-guard-2026-06-04-145354
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-ad-rewards-2026-06-04-144447
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-ad-status-mock-flag-2026-06-05-091639
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-ad-status-mock-flag-fix-2026-06-05-091954
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-apply-web-power-policy-2026-06-04-205414
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-pause-after-worker-start-2026-06-02-140247
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-pause-after-worker-start-2026-06-02-140247.bak-gemma4-e4b-2026-06-03-180022
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-use-start-plan-2026-06-02-174918
.cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-use-start-plan-2026-06-02-174918.bak-gemma4-e4b-2026-06-03-180022
```

### Top static files for PPB

```text
docs/phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan.md
docs/phase-14j-bq-parallel-safe-workstream-plan-and-static-surface-inventory.md
```
