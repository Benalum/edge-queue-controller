# Phase 14J-BX - Controller-Owned Active Source UI Map

PHASE_14J_BX_CONTROLLER_OWNED_ACTIVE_SOURCE_UI_MAP

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_active_source_static_contracts

This document narrows UI patch candidates to active source files and excludes cache/history/output directories.

This phase is not runtime activation.

## Main result

ACTIVE_SOURCE_UI_MAP=completed

ACTIVE_SOURCE_CACHE_EXCLUDED=enabled

The active source map excludes docs, ops history, cleanup history, bridge reports, cache directories, build output, and dependency directories.

## Candidate classes

CANDIDATE_CLASS=controller_public_ui  
CANDIDATE_CLASS=cloudflare_gateway_static_contracts  
CANDIDATE_CLASS=study_ui_static_read_only_candidate  
CANDIDATE_CLASS=companion_ui_static_read_only_candidate  
CANDIDATE_CLASS=calendar_static_read_only_candidate  
CANDIDATE_CLASS=protected_runtime_read_only_only  

## Safe patch boundary

SAFE_UI_PATCH_RULE=controller_owned_static_only

Future UI patches should focus first on controller-owned public UI/static source files. Protected runtime surfaces remain read-only until explicitly approved.

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

## Active source UI map evidence

```text
=== Phase 14J-BX smoke: active source UI map inventory ===
MUTATION_SCOPE=read_only_active_source_map
NO CT101 call
NO model/Ollama endpoint call
NO DB mutation
NO job mutation
NO service restart/reload
NO scheduler activation
NO worker activation
NO runtime activation
ACTIVE_SOURCE_UI_MAP=completed
controller_public_ui_files=29
cloudflare_gateway_files=20
study_ui_static_files=18
companion_ui_static_files=27
calendar_static_files=14
protected_runtime_files=25

--- active UI map controller_public_ui files ---
cloudflare/edge-public-proxy/package.json
cloudflare/edge-public-proxy/src/index.js
cloudflare/edge-public-proxy/wrangler.jsonc
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py

--- active UI map cloudflare_gateway files ---
README.md
bridge.config.json
cloudflare/edge-public-proxy/package.json
cloudflare/edge-public-proxy/src/index.js
cloudflare/edge-public-proxy/wrangler.jsonc
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py

--- active UI map study_ui_static files ---
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_router_lookup.py
edge_router_schema.py
edge_router_seed.py
frontend/study-ui/app.js

--- active UI map companion_ui_static files ---
README.md
bridge.config.json
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_inventory.example.json
edge_modules/chat_queue_creation.py

--- active UI map calendar_static files ---
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_modules/rewarded_ads.py
edge_router_seed.py
frontend/study-ui/app.js
frontend/study-ui/index.html

--- active UI map protected_runtime files ---
README.md
cloudflare/edge-public-proxy/src/index.js
create_stage5p_inspection_pack.sh
edge_controller.py
edge_intent_router.py
edge_inventory.example.json
edge_modules/chat_queue_creation.py
edge_modules/chat_queue_persistence.py

PASS: controller-owned active source UI map inventory completed
```
