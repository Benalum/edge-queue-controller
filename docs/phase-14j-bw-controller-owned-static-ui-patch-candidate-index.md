# Phase 14J-BW - Controller-Owned Static UI Patch Candidate Index

PHASE_14J_BW_CONTROLLER_OWNED_STATIC_UI_PATCH_CANDIDATE_INDEX

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts

This document narrows future static UI work to active source files only.

This phase is not runtime activation.

## Inventory rule

ACTIVE_SOURCE_ONLY_INVENTORY=created

The active source inventory excludes historical docs, generated docs, cleanup docs, bridge reports, archive backups, and smoke-operation history.

This prevents future safe UI work from being slowed down by old project history.

DOCS_NOISE_EXCLUDED=enabled

## Static UI patch candidates

STATIC_UI_PATCH_CANDIDATES=identified

Candidate classes:

CANDIDATE_CLASS=controller_owned_public_pages  
CANDIDATE_CLASS=controller_owned_account_profile_credits_system  
CANDIDATE_CLASS=controller_owned_wrapper_static_assets  
CANDIDATE_CLASS=cloudflare_public_gateway_static_contracts  
CANDIDATE_CLASS=protected_ct101_app_surfaces_read_only_only  

## Safe patch rule

SAFE_UI_PATCH_RULE=controller_owned_static_only

Future static UI patches may proceed in a batched phase only when all are true:

1. The patch is limited to active controller-owned source files.
2. The patch is copy/layout/static contract only.
3. No CT101 call is needed.
4. No model/Ollama call is needed.
5. No DB or job mutation is needed.
6. No service restart/reload is needed.
7. Concise or ultra-concise static baseline passes.
8. Runtime approval boundary remains intact.

## Protected surfaces

PROTECTED_RUNTIME_SURFACES=read_only_until_explicit_approval

Protected surfaces include CT101-backed Study, Companion, and Calendar app behavior; model/Ollama behavior; scheduler/worker lane behavior; router rollout; and warmup execution.

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

## Active source-only inventory evidence

```text
=== Phase 14J-BW smoke: active source-only UI/route inventory ===
MUTATION_SCOPE=read_only_active_source_static_inventory
NO CT101 call
NO model/Ollama endpoint call
NO DB mutation
NO job mutation
NO service restart/reload
NO scheduler activation
NO worker activation
NO runtime activation
ACTIVE_SOURCE_ONLY_INVENTORY=completed
controller_owned_routes_files=28
product_surfaces_files=34
ui_static_files=28
gateway_proxy_files=29
runtime_sensitive_files=24

--- active source top controller_owned_routes files ---
.wrangler/cache/pages.json
.wrangler/cache/wrangler-account.json
cloudflare/edge-public-proxy/src/index.js
cloudflare/edge-public-proxy/wrangler.jsonc
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py
edge_modules/credit_helpers.py
edge_modules/credits.py
edge_modules/email_verification.py
edge_modules/laptop_queue.py
edge_modules/rewarded_ads.py
frontend/study-ui/.wrangler/cache/pages.json

--- active source top product_surfaces files ---
.wrangler/cache/pages.json
.wrangler/cache/wrangler-account.json
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_inventory.example.json
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py
edge_modules/chat_queue_real_user_creation.py
edge_modules/chat_queue_real_user_guard.py
edge_modules/credit_helpers.py
edge_modules/credits.py
edge_modules/email_verification.py
edge_modules/laptop_queue.py

--- active source top ui_static files ---
.wrangler/cache/pages.json
bridge.config.json
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_modules/chat_queue_real_user_guard.py
edge_modules/email_verification.py
edge_modules/laptop_queue.py
edge_modules/rewarded_ads.py
edge_router_schema.py
edge_router_seed.py
frontend/study-ui/.wrangler/cache/pages.json
frontend/study-ui/app.js
frontend/study-ui/index.html

--- active source top gateway_proxy files ---
README.md
bridge.config.json
cloudflare/edge-public-proxy/package.json
cloudflare/edge-public-proxy/src/index.js
cloudflare/edge-public-proxy/wrangler.jsonc
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_inventory.example.json
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py
edge_modules/chat_queue_real_user_creation.py
edge_modules/chat_queue_real_user_guard.py
edge_modules/chat_queue_session_auth.py
edge_modules/email_verification.py

--- active source top runtime_sensitive files ---
README.md
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_inventory.example.json
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py
edge_modules/chat_queue_real_user_creation.py
edge_modules/chat_queue_real_user_guard.py
edge_modules/chat_queue_session_auth.py
edge_modules/laptop_queue.py
edge_router_lookup.py
edge_router_schema.py
edge_router_seed.py

PASS: active source-only UI/route inventory completed
```
