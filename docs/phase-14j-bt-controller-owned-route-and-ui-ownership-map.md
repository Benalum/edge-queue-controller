# Phase 14J-BT - Controller-Owned Route and UI Ownership Map

PHASE_14J_BT_CONTROLLER_OWNED_ROUTE_AND_UI_OWNERSHIP_MAP

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_static_contracts

This document records a static ownership map for controller-owned public routes and UI surfaces.

This is not runtime activation.

## Ownership principles

CONTROLLER_OWNED_SURFACES=static_public_controller_routes

Controller-owned surfaces are safe candidates for future local static/UI polish when they do not require CT101, model calls, Ollama calls, production job mutation, DB mutation, service restart, scheduler activation, or worker activation.

Likely controller-owned areas:

- login/register page surface
- profile/account page surface
- credits/rewarded ads page surface
- system/admin/status page surface
- controller-owned public gateway status contracts
- local static wrapper copy/layout contracts

PROXY_OR_APP_SURFACES=protected_runtime_or_ct101_boundaries

Protected app/proxy areas need additional caution:

- Study app surfaces
- Companion app surfaces
- Calendar app surfaces
- CT101-backed APIs
- model/Ollama-backed runtime behavior
- scheduler/worker lane behavior

## Safe patch rule

SAFE_UI_PATCH_RULE=controller_owned_static_only

Future UI/static patches may be batched when all are true:

1. Files are local to the controller repo.
2. Patch is static copy/layout/contract only.
3. No CT101/model/Ollama endpoint call is needed.
4. No DB/job mutation is needed.
5. No service restart/reload is needed.
6. Existing static and parked-runtime smokes pass.
7. Runtime approval boundary remains intact.

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

Runtime activation remains blocked unless explicitly approved in a later bounded phase.

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
