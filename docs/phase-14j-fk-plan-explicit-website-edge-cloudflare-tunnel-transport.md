# Phase 14J-FK - Plan explicit website-edge Cloudflare tunnel transport

Date: 2026-06-17

## Phase marker

PHASE_14J_FK_PLAN_EXPLICIT_WEBSITE_EDGE_CLOUDFLARE_TUNNEL_TRANSPORT

## Purpose

Record the explicit transport decision for moving the public website runtime toward website-edge safely and quickly.

This phase is docs/smoke-only. It does not install cloudflared, create a tunnel, mutate Cloudflare routes, create a test hostname, or perform production cutover.

## Previous checkpoint

Previous phase: Phase 14J-FJ - Read-only Cloudflare route and tunnel inventory
Previous commit: 052ca89
Previous tag: controller-phase-14j-fj-read-only-cloudflare-route-and-tunnel-inventory-2026-06-17

## Mutation scope

MUTATION_SCOPE=docs_smoke_only_explicit_cloudflare_tunnel_transport_plan

This FK phase performs only:

- laptop repo documentation
- laptop repo smoke script creation
- commit, tag, and push

This FK phase does not mutate website-edge, Cloudflare, nginx, Tailscale, Proxmox, controller/queue, workers, databases, CT101, or model endpoints.

## Current known state from FJ

FJ_REMOTE_CLOUDFLARE_API_CALL_PERFORMED=no
FJ_CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no
FJ_CLOUDFLARE_TEST_ROUTE_APPLY_PERFORMED=no
FJ_CLOUDFLARED_INSTALL_PERFORMED=no
FJ_CLOUDFLARED_PRESENT_ON_LAPTOP=yes
FJ_WRANGLER_PRESENT_ON_LAPTOP=no
FJ_LOCAL_CLOUDFLARED_CONFIG_DIR_PRESENT_ON_LAPTOP=yes
FJ_REPO_EDGE_PUBLIC_PROXY_PRESENT=yes
FJ_PUBLIC_GATEWAY_PRESENT=yes
FJ_WRAPPER_STATIC_HEADERS_PRESENT=yes
FJ_WRAPPER_STATIC_REDIRECTS_PRESENT=yes

## Current website-edge runtime state

WEBSITE_EDGE_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_APPLY_PASSED=yes
WEBSITE_EDGE_NGINX_LOCAL_PORT=18080
WEBSITE_EDGE_NGINX_LISTENER_SCOPE=loopback_only
WEBSITE_EDGE_NGINX_LOCAL_ORIGIN=http_127_0_0_1_18080
WEBSITE_EDGE_CLOUDFLARED_ABSENT=yes
WEBSITE_EDGE_DOCKER_ABSENT=yes
WEBSITE_EDGE_NODE_NPM_ABSENT=yes
WEBSITE_EDGE_SOURCE_CHECKOUT_REMAINED_CLEAN=yes
WEBSITE_EDGE_CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no
WEBSITE_EDGE_CLOUDFLARE_TEST_ROUTE_PERFORMED=no

## Transport decision

TRANSPORT_DECISION=dedicated_website_edge_cloudflare_tunnel_to_loopback_nginx
TRANSPORT_ORIGIN=website_edge_nginx_loopback_127_0_0_1_18080
TRANSPORT_PUBLIC_SCOPE=temporary_test_hostname_only
TRANSPORT_PRODUCTION_SCOPE=no_apex_cutover_no_primary_route_replacement
TRANSPORT_CONTROLLER_SCOPE=no_controller_queue_migration
TRANSPORT_WORKER_SCOPE=no_worker_start_no_model_runtime
TRANSPORT_PROXMOX_SCOPE=no_public_proxmox_controls

The selected transport path is:

- website-edge runs nginx locally for static wrapper files
- nginx remains bound to loopback only on website-edge
- website-edge later runs cloudflared as an outbound connector
- cloudflared points to the local nginx origin
- Cloudflare exposes only a temporary test hostname first
- apex/root production route remains unchanged until a later separately approved cutover

## Credential decision

CREDENTIAL_DECISION=prefer_new_dedicated_cloudflare_tunnel_token_or_scoped_token
GLOBAL_API_KEY_ALLOWED=no
BROAD_ACCOUNT_TOKEN_ALLOWED=no
DEDICATED_TOKEN_ALLOWED=yes
TOKEN_PRINTING_ALLOWED=no
TOKEN_COMMIT_ALLOWED=no
TOKEN_SOURCE_FILE_ALLOWED=no
TOKEN_APC_LAST_OUTPUT_ALLOWED=no
TOKEN_INTERACTIVE_ENTRY_REQUIRED=yes
TOKEN_ROTATION_AFTER_STABLE_MIGRATION_RECOMMENDED=yes

A new dedicated Cloudflare credential is acceptable and preferred if it reduces risk.

Preferred credential type:

- Cloudflare dashboard-managed tunnel token, or
- narrowly scoped Cloudflare API token if a CLI/API route is later explicitly approved

Do not use the global API key.

Do not paste a token into a command that is captured by tee or APC_LAST_OUTPUT.

A later token-handling command must use an interactive hidden prompt or a manually created root-owned environment file that is never printed.

## Future phase sequence

The safe future sequence should be:

1. Phase 14J-FL: website-edge cloudflared install-only plan or apply.
2. Phase 14J-FM: website-edge cloudflared tunnel token/service setup for temporary test hostname only.
3. Phase 14J-FN: public test hostname smoke and rollback verification.
4. Phase 14J-FO: production cutover plan only.
5. Phase 14J-FP or later: production cutover apply only after explicit approval.

The next mutation should not combine install, tunnel setup, test hostname, and production cutover in one step.

## Future FL install-only allowed scope

FUTURE_FL_ALLOWED_WEBSITE_EDGE_ONLY=yes
FUTURE_FL_ALLOWED_CLOUDFLARED_INSTALL_ONLY=yes
FUTURE_FL_ALLOWED_PACKAGE_SIGNATURE_OR_SOURCE_VERIFICATION=yes
FUTURE_FL_ALLOWED_VERSION_CHECK=yes
FUTURE_FL_ALLOWED_NO_TUNNEL_AUTH_TOKEN=yes
FUTURE_FL_ALLOWED_NO_CLOUDFLARE_ROUTE_MUTATION=yes
FUTURE_FL_ALLOWED_NO_TEST_HOSTNAME_APPLY=yes
FUTURE_FL_ALLOWED_NO_PRODUCTION_CUTOVER=yes

## Future FM tunnel setup allowed scope after separate approval

FUTURE_FM_ALLOWED_WEBSITE_EDGE_ONLY=yes
FUTURE_FM_ALLOWED_DEDICATED_TUNNEL_TOKEN_ONLY=yes
FUTURE_FM_ALLOWED_INTERACTIVE_SECRET_ENTRY_ONLY=yes
FUTURE_FM_ALLOWED_CLOUDFLARED_SERVICE_FOR_STATIC_WRAPPER_TUNNEL=yes
FUTURE_FM_ALLOWED_ORIGIN_127_0_0_1_18080=yes
FUTURE_FM_ALLOWED_TEMPORARY_TEST_HOSTNAME_ONLY=yes
FUTURE_FM_ALLOWED_LOCAL_NGINX_HEALTH_CHECK_BEFORE_TUNNEL=yes
FUTURE_FM_ALLOWED_ROLLBACK_PLAN_REQUIRED=yes

## Future denied scope

FUTURE_DENY_GLOBAL_CLOUDFLARE_API_KEY=yes
FUTURE_DENY_TOKEN_PRINTING=yes
FUTURE_DENY_TOKEN_COMMIT=yes
FUTURE_DENY_TOKEN_IN_SOURCE_FILES=yes
FUTURE_DENY_TOKEN_IN_APC_LAST_OUTPUT=yes
FUTURE_DENY_APEX_PRODUCTION_CUTOVER=yes
FUTURE_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes
FUTURE_DENY_PROXMOX_PUBLIC_EXPOSURE=yes
FUTURE_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_DENY_WORKER_START=yes
FUTURE_DENY_RUNTIME_ACTIVATION_EXCEPT_STATIC_TUNNEL=yes
FUTURE_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_DENY_CT101_CALL=yes
FUTURE_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_DENY_DOCKER_INSTALL=yes
FUTURE_DENY_NODE_NPM_INSTALL=yes
FUTURE_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_DENY_SUBNET_ROUTES=yes
FUTURE_DENY_EXIT_NODE=yes
FUTURE_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Rollback requirements for later tunnel setup

ROLLBACK_REQUIRED_BEFORE_TEST_HOSTNAME_APPLY=yes
ROLLBACK_MUST_DISABLE_CLOUDFLARED_SERVICE=yes
ROLLBACK_MUST_REMOVE_TEMP_TEST_HOSTNAME_ROUTE_IF_CREATED=yes
ROLLBACK_MUST_LEAVE_NGINX_LOCAL_RUNTIME_SAFE=yes
ROLLBACK_MUST_NOT_TOUCH_CONTROLLER_QUEUE=yes
ROLLBACK_MUST_NOT_TOUCH_CT101_OR_MODELS=yes
ROLLBACK_MUST_NOT_TOUCH_PRODUCTION_APEX_ROUTE=yes

## Result

PHASE_14J_FK_RESULT=explicit_website_edge_cloudflare_tunnel_transport_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=approve_website_edge_cloudflared_install_only_without_tunnel_auth_or_route_mutation

The next phase requires explicit approval because it would install cloudflared on website-edge. It should not authenticate a tunnel, create a public hostname, mutate Cloudflare routes, or perform production cutover.
