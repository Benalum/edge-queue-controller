# Phase 14J-FG - Plan nginx static wrapper local runtime without Cloudflare cutover

Date: 2026-06-17

## Phase marker

PHASE_14J_FG_PLAN_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_WITHOUT_CLOUDFLARE_CUTOVER

## Purpose

Record a docs/smoke-only plan for the next narrow website-edge validation step after Phase 14J-FF.

The next VM-side phase should configure nginx to serve the already-verified public wrapper static files locally on website-edge, but it must not perform any Cloudflare route change or production cutover.

## Previous checkpoint

Previous phase: Phase 14J-FF - Website-edge temporary loopback static server smoke
Previous commit: 4868f05
Previous tag: controller-phase-14j-ff-website-edge-temporary-loopback-static-server-smoke-2026-06-17

## Mutation scope for this phase

MUTATION_SCOPE=docs_smoke_only_nginx_static_wrapper_local_runtime_plan

This FG phase performs only:

- laptop repo documentation
- laptop repo smoke script creation
- commit, tag, and push

This FG phase does not mutate website-edge.

## Current website-edge state from FF

WEBSITE_EDGE_LOOPBACK_STATIC_SERVER_SMOKE_PASSED=yes
WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e
WEBSITE_EDGE_CHECKOUT_TAG=controller-phase-14j-fc-inspect-public-wrapper-entrypoints-and-plan-local-only-clone-smoke-2026-06-17
WEBSITE_EDGE_SPARSE_MODE=non-cone
WEBSITE_EDGE_SPARSE_SCOPE=frontend/wrapper-ui,frontend/study-ui
WEBSITE_EDGE_ACTUAL_WORKTREE_FILE_COUNT=18
WEBSITE_EDGE_TEMPORARY_SERVER_STOPPED_BEFORE_EXIT=yes
WEBSITE_EDGE_CHECKOUT_REMAINED_CLEAN_AFTER_LOOPBACK_SMOKE=yes
WEBSITE_EDGE_DOCKER_ABSENT=yes
WEBSITE_EDGE_CLOUDFLARED_ABSENT=yes
WEBSITE_EDGE_NODE_NPM_ABSENT=yes

## Future VM-side nginx local runtime target

The next approved VM-side phase should:

- run inside website-edge SSH session only
- use the existing verified non-cone sparse checkout
- copy only frontend/wrapper-ui static files to a non-secret nginx document root
- configure nginx for local/static wrapper serving only
- test nginx config before reload
- reload or restart nginx only if config test passes
- perform local curl checks only
- verify root index, app.js, styles.css, and queued_chat_config.js
- leave Cloudflare untouched
- leave Tailscale policy untouched
- avoid installing Node/npm
- avoid installing Docker
- avoid installing cloudflared
- avoid controller/queue migration
- avoid workers and runtime activation
- avoid CT101/model calls
- avoid production DB/job mutation

## Future VM-side nginx local runtime allowed scope

FUTURE_NGINX_LOCAL_ALLOWED_USE_EXISTING_SPARSE_CHECKOUT=yes
FUTURE_NGINX_LOCAL_ALLOWED_COPY_WRAPPER_STATIC_FILES=yes
FUTURE_NGINX_LOCAL_ALLOWED_CREATE_NONSECRET_DOCROOT=yes
FUTURE_NGINX_LOCAL_ALLOWED_CREATE_NGINX_LOCAL_SITE_CONFIG=yes
FUTURE_NGINX_LOCAL_ALLOWED_NGINX_CONFIG_TEST=yes
FUTURE_NGINX_LOCAL_ALLOWED_RELOAD_NGINX_ONLY_AFTER_CONFIG_TEST=yes
FUTURE_NGINX_LOCAL_ALLOWED_LOCAL_CURL_ONLY=yes
FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_INDEX_HTML=yes
FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_APP_JS=yes
FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_STYLES_CSS=yes
FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_CONFIG_JS=yes

## Future VM-side nginx local runtime denied scope

FUTURE_NGINX_LOCAL_DENY_CLOUDFLARE_TEST_ROUTE=yes
FUTURE_NGINX_LOCAL_DENY_CLOUDFLARE_PRODUCTION_CUTOVER=yes
FUTURE_NGINX_LOCAL_DENY_CLOUDFLARED_INSTALL=yes
FUTURE_NGINX_LOCAL_DENY_DOCKER_INSTALL=yes
FUTURE_NGINX_LOCAL_DENY_NODE_NPM_INSTALL=yes
FUTURE_NGINX_LOCAL_DENY_SYSTEMD_APP_RUNTIME_CREATION=yes
FUTURE_NGINX_LOCAL_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_NGINX_LOCAL_DENY_WORKER_START=yes
FUTURE_NGINX_LOCAL_DENY_RUNTIME_ACTIVATION=yes
FUTURE_NGINX_LOCAL_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_NGINX_LOCAL_DENY_CT101_CALL=yes
FUTURE_NGINX_LOCAL_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_NGINX_LOCAL_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_NGINX_LOCAL_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_NGINX_LOCAL_DENY_SUBNET_ROUTES=yes
FUTURE_NGINX_LOCAL_DENY_EXIT_NODE=yes
FUTURE_NGINX_LOCAL_DENY_PROXMOX_PUBLIC_CONTROLS=yes
FUTURE_NGINX_LOCAL_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_NGINX_LOCAL_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Planned VM-side validation checks

The future VM-side nginx local runtime apply should verify:

- hostname is website-edge
- OS is Ubuntu 26.04
- checkout is still at head 03a6b4e
- sparse mode remains non-cone
- sparse scope remains frontend/wrapper-ui and frontend/study-ui
- source checkout stays clean
- Docker, cloudflared, node, and npm remain absent
- nginx is installed and active before apply
- backup of previous default nginx config is created if changed
- nginx config test passes
- nginx reload or restart succeeds only after config test
- local GET / returns HTTP 200
- local GET /app.js returns HTTP 200
- local GET /styles.css returns HTTP 200
- local GET /queued_chat_config.js returns HTTP 200
- copied files match expected wrapper static file hashes
- no Cloudflare route or cutover occurred
- no app systemd service was created
- no controller/queue/worker/runtime activation occurred

## Rollback expectations

The future VM-side nginx local runtime apply should include a rollback path:

- back up changed nginx site files before mutation
- restore previous nginx config on failed config test or failed local curl smoke
- reload nginx only after restoration passes config test
- leave the verified source checkout untouched
- leave Cloudflare untouched
- leave Tailscale untouched
- leave controller/queue/workers untouched

## Result

PHASE_14J_FG_RESULT=nginx_static_wrapper_local_runtime_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=approve_website_edge_nginx_static_wrapper_local_runtime_apply_without_cloudflare_cutover

The next phase requires explicit approval because it would mutate nginx configuration inside website-edge, even though it should remain local-only and perform no Cloudflare route or production cutover.
