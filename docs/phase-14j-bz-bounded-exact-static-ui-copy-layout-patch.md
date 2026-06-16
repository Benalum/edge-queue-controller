# Phase 14J-BZ - Bounded Exact Static UI Copy/Layout Patch

PHASE_14J_BZ_BOUNDED_EXACT_STATIC_UI_COPY_LAYOUT_PATCH

Date: 2026-06-16

## Scope

MUTATION_SCOPE=active_source_static_ui_copy_layout_only

This phase performs the first bounded static UI copy/layout patch batch after the BY source-shape plan.

This phase is not runtime activation.

## Main result

STATIC_UI_PATCH_APPLIED=bounded_exact_static_copy_layout

PATCH_BOUNDARY=tracked_active_static_ui_source_only

## Added artifacts

BZ_ARTIFACTS_ADDED=three

1. `docs/phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.md`
2. `docs/phase-14j-bz-static-ui-copy-layout-patch-manifest.md`
3. `ops/smoke/check-phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.sh`

## Source refresh cadence

SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate

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

NEXT_SAFE_PHASE=phase_14j_ca_static_ui_patch_verification_and_milestone_decision

Phase 14J-CA should verify the static UI patch, then decide whether to keep batching safe UI work or create a milestone Source refresh package.

## Patch application evidence

```text
STATIC_UI_PATCH_APPLIED=bounded_exact_static_copy_layout
patched=frontend/study-ui/index.html
patched=frontend/study-ui/app.js
skipped=index.html:missing_or_untracked
skipped=app.js:missing_or_untracked
PASS: bounded static UI copy/layout patch applied
```
