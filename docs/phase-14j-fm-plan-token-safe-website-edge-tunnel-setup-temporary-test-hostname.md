# Phase 14J-FM - Plan token-safe website-edge tunnel setup for temporary test hostname

Date: 2026-06-17

## Phase marker

PHASE_14J_FM_PLAN_TOKEN_SAFE_WEBSITE_EDGE_TUNNEL_SETUP_TEMPORARY_TEST_HOSTNAME

## Purpose

Record the token-safe plan for connecting website-edge cloudflared to Cloudflare Tunnel with a temporary test hostname only.

This phase is docs/smoke-only. It does not use a token, authenticate a tunnel, create a service, create a test hostname, mutate Cloudflare routes, or perform production cutover.

## Previous checkpoint

Previous phase: Phase 14J-FL - Website-edge cloudflared install-only
Previous commit: 66e4c4b
Previous tag: controller-phase-14j-fl-website-edge-cloudflared-install-only-2026-06-17

## Mutation scope

MUTATION_SCOPE=docs_smoke_only_token_safe_tunnel_setup_plan

This FM phase performs only:

- laptop repo documentation
- laptop repo smoke script creation
- commit, tag, and push

This FM phase does not mutate website-edge, Cloudflare, nginx, Tailscale, Proxmox, controller/queue, workers, databases, CT101, or model endpoints.

## Current state from FL

WEBSITE_EDGE_CLOUDFLARED_INSTALL_ONLY_PASSED=yes
WEBSITE_EDGE_CLOUDFLARED_PATH=/usr/local/bin/cloudflared
WEBSITE_EDGE_CLOUDFLARED_VERSION=2026.6.0
WEBSITE_EDGE_CLOUDFLARED_SYSTEMD_UNIT_CREATED_OR_ENABLED=no
WEBSITE_EDGE_CLOUDFLARED_PROCESS_RUNNING_AFTER_INSTALL=no
WEBSITE_EDGE_CLOUDFLARE_TOKEN_USED=no
WEBSITE_EDGE_CLOUDFLARE_TUNNEL_AUTHENTICATED=no
WEBSITE_EDGE_CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no
WEBSITE_EDGE_CLOUDFLARE_TEST_HOSTNAME_CREATED=no
WEBSITE_EDGE_CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no
WEBSITE_EDGE_NGINX_LOCAL_RUNTIME_HEALTHY_AFTER_FL=yes
WEBSITE_EDGE_NGINX_LOCAL_PORT=18080
WEBSITE_EDGE_NGINX_LOCAL_ORIGIN=http_127_0_0_1_18080
WEBSITE_EDGE_DOCKER_ABSENT=yes
WEBSITE_EDGE_NODE_NPM_ABSENT=yes
WEBSITE_EDGE_SOURCE_CHECKOUT_REMAINED_CLEAN=yes

## Tunnel setup decision

TUNNEL_SETUP_DECISION=cloudflare_dashboard_managed_tunnel_token_to_website_edge_cloudflared
TUNNEL_ORIGIN_SERVICE=http_127_0_0_1_18080
TUNNEL_HOSTNAME_SCOPE=temporary_test_hostname_only
TUNNEL_PRODUCTION_SCOPE=no_apex_cutover_no_primary_route_replacement
TUNNEL_INSTALL_SCOPE=no_new_package_install_cloudflared_already_installed
TUNNEL_CONTROLLER_SCOPE=no_controller_queue_migration
TUNNEL_WORKER_SCOPE=no_worker_start_no_model_runtime
TUNNEL_PROXMOX_SCOPE=no_public_proxmox_controls

Recommended future path:

1. Create a dedicated Cloudflare Tunnel in the Cloudflare dashboard.
2. Assign only a temporary test hostname.
3. Set the tunnel public hostname service to the website-edge local nginx origin.
4. Copy only the tunnel token for a one-time interactive entry on website-edge.
5. Do not paste the token into ChatGPT or into a logged command.
6. Install/run the cloudflared service using the token without echoing it.
7. Verify local nginx health before starting the service.
8. Verify cloudflared service health without printing secrets.
9. Smoke the temporary hostname only.
10. Leave apex/root production unchanged until a later approved cutover.

## Credential handling plan

CREDENTIAL_TYPE=dedicated_cloudflare_tunnel_token
GLOBAL_API_KEY_ALLOWED=no
BROAD_ACCOUNT_TOKEN_ALLOWED=no
DEDICATED_TUNNEL_TOKEN_ALLOWED=yes
TOKEN_PRINTING_ALLOWED=no
TOKEN_COMMIT_ALLOWED=no
TOKEN_SOURCE_FILE_ALLOWED=no
TOKEN_APC_LAST_OUTPUT_ALLOWED=no
TOKEN_CHATGPT_PASTE_ALLOWED=no
TOKEN_INTERACTIVE_HIDDEN_ENTRY_REQUIRED=yes
TOKEN_ENV_FILE_PRINTING_ALLOWED=no
TOKEN_ROTATION_AFTER_STABLE_MIGRATION_RECOMMENDED=yes

The future mutation command must not include the token in the pasted command text.

The future mutation command should read the token interactively using a hidden prompt inside the website-edge SSH session.

## Future FN setup allowed scope after separate approval

FUTURE_FN_ALLOWED_WEBSITE_EDGE_ONLY=yes
FUTURE_FN_ALLOWED_USE_EXISTING_CLOUDFLARED_BINARY=yes
FUTURE_FN_ALLOWED_DEDICATED_TUNNEL_TOKEN_ONLY=yes
FUTURE_FN_ALLOWED_INTERACTIVE_HIDDEN_TOKEN_ENTRY_ONLY=yes
FUTURE_FN_ALLOWED_CREATE_CLOUDFLARED_SERVICE=yes
FUTURE_FN_ALLOWED_START_CLOUDFLARED_SERVICE=yes
FUTURE_FN_ALLOWED_ENABLE_CLOUDFLARED_SERVICE_ONLY_IF_HEALTHY=yes
FUTURE_FN_ALLOWED_ORIGIN_127_0_0_1_18080=yes
FUTURE_FN_ALLOWED_TEMPORARY_TEST_HOSTNAME_ONLY=yes
FUTURE_FN_ALLOWED_NGINX_LOCAL_HEALTH_CHECK_BEFORE_SERVICE=yes
FUTURE_FN_ALLOWED_NGINX_LOCAL_HEALTH_CHECK_AFTER_SERVICE=yes
FUTURE_FN_ALLOWED_CLOUDFLARED_VERSION_CHECK=yes
FUTURE_FN_ALLOWED_SERVICE_STATUS_SANITIZED=yes
FUTURE_FN_ALLOWED_ROLLBACK_DISABLE_SERVICE=yes
FUTURE_FN_ALLOWED_ROLLBACK_REMOVE_SERVICE_CONFIG=yes
FUTURE_FN_ALLOWED_ROLLBACK_NO_PRODUCTION_ROUTE_TOUCH=yes

## Future FN denied scope

FUTURE_FN_DENY_TOKEN_PRINTING=yes
FUTURE_FN_DENY_TOKEN_IN_COMMAND_HISTORY_WHERE_AVOIDABLE=yes
FUTURE_FN_DENY_TOKEN_COMMIT=yes
FUTURE_FN_DENY_TOKEN_IN_SOURCE_FILES=yes
FUTURE_FN_DENY_TOKEN_IN_APC_LAST_OUTPUT=yes
FUTURE_FN_DENY_TOKEN_IN_CHATGPT=yes
FUTURE_FN_DENY_GLOBAL_CLOUDFLARE_API_KEY=yes
FUTURE_FN_DENY_BROAD_ACCOUNT_TOKEN=yes
FUTURE_FN_DENY_APEX_PRODUCTION_CUTOVER=yes
FUTURE_FN_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes
FUTURE_FN_DENY_PROXMOX_PUBLIC_EXPOSURE=yes
FUTURE_FN_DENY_NGINX_CONFIG_MUTATION=yes
FUTURE_FN_DENY_DOCKER_INSTALL=yes
FUTURE_FN_DENY_NODE_NPM_INSTALL=yes
FUTURE_FN_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_FN_DENY_WORKER_START=yes
FUTURE_FN_DENY_RUNTIME_ACTIVATION_EXCEPT_STATIC_TUNNEL=yes
FUTURE_FN_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_FN_DENY_CT101_CALL=yes
FUTURE_FN_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_FN_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_FN_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_FN_DENY_SUBNET_ROUTES=yes
FUTURE_FN_DENY_EXIT_NODE=yes
FUTURE_FN_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_FN_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Rollback requirements

ROLLBACK_FN_REQUIRED=yes
ROLLBACK_FN_DISABLE_CLOUDFLARED_SERVICE=yes
ROLLBACK_FN_STOP_CLOUDFLARED_PROCESS=yes
ROLLBACK_FN_REMOVE_CLOUDFLARED_SERVICE_CONFIG_IF_CREATED=yes
ROLLBACK_FN_LEAVE_CLOUDFLARED_BINARY_INSTALLED=yes
ROLLBACK_FN_LEAVE_NGINX_LOCAL_RUNTIME_SAFE=yes
ROLLBACK_FN_DO_NOT_TOUCH_PRODUCTION_APEX_ROUTE=yes
ROLLBACK_FN_DO_NOT_TOUCH_CONTROLLER_QUEUE=yes
ROLLBACK_FN_DO_NOT_TOUCH_CT101_OR_MODELS=yes
ROLLBACK_FN_DO_NOT_TOUCH_PROXMOX_PUBLIC_CONTROLS=yes

## Manual Cloudflare dashboard prerequisites for future FN

Before the future FN apply command, create or confirm in Cloudflare dashboard:

- a dedicated tunnel for website-edge
- a temporary test hostname only
- service target is the website-edge local nginx origin
- no apex/root production route replacement
- no Proxmox management route
- no CT101/model route
- no controller/queue migration route
- a one-time tunnel token available for interactive entry only

Do not paste the tunnel token into this repository, ChatGPT, shell history, APC_LAST_OUTPUT, or any Source file.

## Result

PHASE_14J_FM_RESULT=token_safe_website_edge_tunnel_setup_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=approve_website_edge_cloudflared_token_service_setup_for_temporary_test_hostname_without_production_cutover

The next phase requires explicit approval because it will use a Cloudflare tunnel token and create/start a cloudflared service on website-edge. It must still avoid production cutover, apex route replacement, Proxmox public exposure, controller/queue migration, CT101/model calls, and token printing.
