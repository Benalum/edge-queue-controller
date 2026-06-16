# Phase 14J-BT - Controller-Owned Static UI and Route Contract Batch

PHASE_14J_BT_CONTROLLER_OWNED_STATIC_UI_AND_ROUTE_CONTRACT_BATCH

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_static_contracts

This phase converts the BR/BS static coverage into a faster reusable baseline for future controller-owned UI and route contract work.

This phase is not runtime activation.

## Added artifacts

BT_ARTIFACTS_ADDED=three

1. `docs/phase-14j-bt-controller-owned-route-and-ui-ownership-map.md`
2. `ops/smoke/check-phase-14j-bt-controller-owned-route-and-ui-ownership-map.sh`
3. `ops/smoke/check-phase-14j-safe-static-baseline.sh`

## Safe baseline result

SAFE_STATIC_BASELINE_SMOKE=created

The new baseline smoke chains BL through BS plus BR/BS reusable static smokes and the BT route/UI ownership map check.

This gives future safe batches one main baseline command before commit/tag/push.

## Safe controller-owned UI rule

SAFE_UI_PATCH_RULE=controller_owned_static_only

Safe UI/route patches can move faster when they are controller-owned, static, local, and do not require runtime activation or CT101/model/job/DB behavior.

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

NEXT_SAFE_PHASE=phase_14j_bu_controller_owned_static_ui_patch_batch_or_milestone_consolidation

Phase 14J-BU can now either:

1. perform a larger controller-owned static UI/docs patch batch, or
2. consolidate BL through BT into a milestone checkpoint before any runtime approval discussion.

## Static route/UI inventory evidence

```text
=== Phase 14J-BT static route/UI inventory ===
controller_owned_candidates=912
proxy_or_app_candidates=310
ui_candidates=892
runtime_sensitive_candidates=1137

--- top controller_owned_candidates files ---
.cgpt-bridge/validate.sh
.cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/src/index.js
.cleanup-archive/dev-server-before-study-preview-2026-06-10-192901.py
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/deletion-plan.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/final-route-ownership.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/laptop-owned-platform-architecture-2026-06-10.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k10-study-preview-live-link-2026-06-10-200808/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k12-study-preview-deck-switch-2026-06-10-201443/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k13-study-preview-create-deck-2026-06-10-201554/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k14-study-preview-add-card-2026-06-10-201801/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k15-study-preview-review-queue-2026-06-10-202119/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k16-study-preview-review-submit-2026-06-10-202503/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192057/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192104/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192616/frontend/study-ui/index.html
.cleanup-archive/stage5k6-study-preview-hydrator-2026-06-10-195217/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k7-study-preview-card-stats-2026-06-10-195532/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k8-study-preview-readonly-2026-06-10-200012/frontend/wrapper-ui/app.js
.cleanup-archive/stage5l4d-direct-queued-chat-trusted-headers-2026-06-10-205343/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5l8-minimal-queued-chat-ui-2026-06-10-211824/frontend/wrapper-ui/app.js

--- top proxy_or_app_candidates files ---
.cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/src/index.js
.cleanup-archive/dev-server-before-study-preview-2026-06-10-192901.py
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/deletion-plan.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/final-route-ownership.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/laptop-owned-platform-architecture-2026-06-10.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/study-direct-laptop-api-checkpoint-2026-06-10.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k10-study-preview-live-link-2026-06-10-200808/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k12-study-preview-deck-switch-2026-06-10-201443/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k13-study-preview-create-deck-2026-06-10-201554/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k14-study-preview-add-card-2026-06-10-201801/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k15-study-preview-review-queue-2026-06-10-202119/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k16-study-preview-review-submit-2026-06-10-202503/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192057/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192104/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192616/frontend/study-ui/index.html
.cleanup-archive/stage5k6-study-preview-hydrator-2026-06-10-195217/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k7-study-preview-card-stats-2026-06-10-195532/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k8-study-preview-readonly-2026-06-10-200012/frontend/wrapper-ui/app.js
.cleanup-archive/stage5l4d-direct-queued-chat-trusted-headers-2026-06-10-205343/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5l8-minimal-queued-chat-ui-2026-06-10-211824/frontend/wrapper-ui/app.js

--- top ui_candidates files ---
.cgpt-bridge/validate.sh
.cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/src/index.js
.cleanup-archive/dev-server-before-study-preview-2026-06-10-192901.py
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/deletion-plan.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/final-route-ownership.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/laptop-owned-platform-architecture-2026-06-10.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/study-direct-laptop-api-checkpoint-2026-06-10.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/ct101-worker-laptop-queue-integration-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/ct101-worker-laptop-queue-integration-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k10-study-preview-live-link-2026-06-10-200808/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k12-study-preview-deck-switch-2026-06-10-201443/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k13-study-preview-create-deck-2026-06-10-201554/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k14-study-preview-add-card-2026-06-10-201801/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k15-study-preview-review-queue-2026-06-10-202119/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k16-study-preview-review-submit-2026-06-10-202503/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192057/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192104/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192616/frontend/study-ui/index.html
.cleanup-archive/stage5k6-study-preview-hydrator-2026-06-10-195217/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k7-study-preview-card-stats-2026-06-10-195532/frontend/wrapper-ui/app.js

--- top runtime_sensitive_candidates files ---
.cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/src/index.js
.cleanup-archive/dev-server-before-study-preview-2026-06-10-192901.py
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/deletion-plan.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/final-route-ownership.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/laptop-owned-platform-architecture-2026-06-10.md
.cleanup-archive/leftover-cleanup-docs-2026-06-10-190158/study-direct-laptop-api-checkpoint-2026-06-10.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/ct101-worker-laptop-queue-integration-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190613/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/ct101-worker-laptop-queue-integration-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/deploy.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-job-queue-facade-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/laptop-owned-data-plan.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/public-route-map.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/route-ownership.md
.cleanup-archive/stage5j2-stale-route-docs-2026-06-10-190630/docs/single-frontend-owner-plan.md
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j8-finish-wrapper-stale-reference-cleanup-2026-06-10-191706/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/app.js
.cleanup-archive/stage5j9-final-wrapper-comment-sweep-2026-06-10-191745/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k10-study-preview-live-link-2026-06-10-200808/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k12-study-preview-deck-switch-2026-06-10-201443/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k13-study-preview-create-deck-2026-06-10-201554/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k14-study-preview-add-card-2026-06-10-201801/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k15-study-preview-review-queue-2026-06-10-202119/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k16-study-preview-review-submit-2026-06-10-202503/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k19-study-controlled-cutover-2026-06-10-203203/frontend/wrapper-ui/dev_server.py
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192057/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192104/frontend/study-ui/index.html
.cleanup-archive/stage5k2-study-content-partial-2026-06-10-192616/frontend/study-ui/index.html
.cleanup-archive/stage5k6-study-preview-hydrator-2026-06-10-195217/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k7-study-preview-card-stats-2026-06-10-195532/frontend/wrapper-ui/app.js
.cleanup-archive/stage5k8-study-preview-readonly-2026-06-10-200012/frontend/wrapper-ui/app.js

PASS: static route/UI inventory completed
```
