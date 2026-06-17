# Phase 14J-FE - Plan website-edge local loopback static server smoke

Date: 2026-06-17

## Phase marker

PHASE_14J_FE_PLAN_WEBSITE_EDGE_LOCAL_LOOPBACK_STATIC_SERVER_SMOKE

## Purpose

Record a docs/smoke-only plan for the next narrow website-edge validation step after Phase 14J-FD.

The next VM-side phase should run a temporary local loopback static file server against the already-verified sparse checkout and verify that the public wrapper static files can be served locally from website-edge.

## Previous checkpoint

Previous phase: Phase 14J-FD - Website-edge sparse static clone verification
Previous commit: 142be68
Previous tag: controller-phase-14j-fd-website-edge-sparse-static-clone-verification-2026-06-17

## Mutation scope for this phase

MUTATION_SCOPE=docs_smoke_only_local_loopback_static_server_smoke_plan

This FE phase performs only:

- laptop repo documentation
- laptop repo smoke script creation
- commit, tag, and push

This FE phase does not mutate website-edge.

## Current website-edge state from FD

WEBSITE_EDGE_SPARSE_STATIC_CHECKOUT_VERIFIED=yes
WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e
WEBSITE_EDGE_CHECKOUT_TAG=controller-phase-14j-fc-inspect-public-wrapper-entrypoints-and-plan-local-only-clone-smoke-2026-06-17
WEBSITE_EDGE_SPARSE_MODE=non-cone
WEBSITE_EDGE_SPARSE_SCOPE=frontend/wrapper-ui,frontend/study-ui
WEBSITE_EDGE_ACTUAL_WORKTREE_FILE_COUNT=18
WEBSITE_EDGE_REQUIRED_WRAPPER_STATIC_FILES_PRESENT=yes
WEBSITE_EDGE_OPTIONAL_STUDY_STATIC_FILES_PRESENT=yes
WEBSITE_EDGE_SENSITIVE_FILENAME_COUNT=0
WEBSITE_EDGE_RUNTIME_PATH_COUNT=0

## Future VM-side local loopback smoke target

The next approved VM-side phase should:

- run inside website-edge SSH session only
- use the existing verified sparse checkout
- serve only frontend/wrapper-ui from a temporary local loopback Python static server
- bind only to 127.0.0.1
- use a high unprivileged local port
- perform local curl checks from inside website-edge
- stop the temporary server before exit
- leave nginx untouched
- leave systemd untouched
- leave Cloudflare untouched
- avoid installing Node/npm
- avoid installing Docker
- avoid installing cloudflared

## Future VM-side local loopback smoke allowed scope

FUTURE_LOOPBACK_SMOKE_ALLOWED_USE_EXISTING_SPARSE_CHECKOUT=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_TEMPORARY_PYTHON_HTTP_SERVER=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_BIND_127_0_0_1_ONLY=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_LOCAL_CURL_ONLY=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_INDEX_HTML=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_APP_JS=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_STYLES_CSS=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_CONFIG_JS=yes
FUTURE_LOOPBACK_SMOKE_ALLOWED_STOP_TEMP_SERVER=yes

## Future VM-side local loopback smoke denied scope

FUTURE_LOOPBACK_SMOKE_DENY_NGINX_CONFIG_MUTATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_SYSTEMD_RUNTIME_CREATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARE_TEST_ROUTE=yes
FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARE_PRODUCTION_CUTOVER=yes
FUTURE_LOOPBACK_SMOKE_DENY_DOCKER_INSTALL=yes
FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARED_INSTALL=yes
FUTURE_LOOPBACK_SMOKE_DENY_NODE_NPM_INSTALL=yes
FUTURE_LOOPBACK_SMOKE_DENY_APP_DEPLOYMENT=yes
FUTURE_LOOPBACK_SMOKE_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_WORKER_START=yes
FUTURE_LOOPBACK_SMOKE_DENY_RUNTIME_ACTIVATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_CT101_CALL=yes
FUTURE_LOOPBACK_SMOKE_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_LOOPBACK_SMOKE_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_LOOPBACK_SMOKE_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_LOOPBACK_SMOKE_DENY_SUBNET_ROUTES=yes
FUTURE_LOOPBACK_SMOKE_DENY_EXIT_NODE=yes
FUTURE_LOOPBACK_SMOKE_DENY_PROXMOX_PUBLIC_CONTROLS=yes
FUTURE_LOOPBACK_SMOKE_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_LOOPBACK_SMOKE_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Planned VM-side validation checks

The future VM-side loopback smoke should verify:

- hostname is website-edge
- OS is Ubuntu 26.04
- checkout is still at head 03a6b4e
- sparse mode remains non-cone
- sparse scope remains frontend/wrapper-ui and frontend/study-ui
- sensitive filename count remains 0
- runtime path count remains 0
- docker, cloudflared, node, and npm remain absent
- temporary server binds to 127.0.0.1 only
- local GET / returns HTTP 200
- local GET /app.js returns HTTP 200
- local GET /styles.css returns HTTP 200
- local GET /queued_chat_config.js returns HTTP 200
- temporary server is stopped before script exit

## Rollback and cleanup expectations

The future VM-side loopback smoke should be self-cleaning:

- create a temporary runtime directory or pid file only if needed
- kill its own temporary HTTP server on exit
- not alter the checked-out files
- not alter nginx
- not alter systemd
- not alter firewall
- not alter Cloudflare
- not alter Tailscale

## Result

PHASE_14J_FE_RESULT=local_loopback_static_server_smoke_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=approve_website_edge_temporary_loopback_static_server_smoke

The next phase requires explicit approval because it starts a temporary process inside website-edge, even though it should bind only to 127.0.0.1 and stop before exit.
