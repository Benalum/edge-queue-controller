# Phase 14J-FI - Plan Cloudflare test-route feasibility without production cutover

Date: 2026-06-17

## Phase marker

PHASE_14J_FI_PLAN_CLOUDFLARE_TEST_ROUTE_FEASIBILITY_WITHOUT_PRODUCTION_CUTOVER

## Purpose

Record a docs/smoke-only plan for the next safe step after Phase 14J-FH.

Phase 14J-FH configured website-edge nginx to serve the static wrapper locally on loopback port 18080. Because the nginx listener is intentionally loopback-only and cloudflared is not installed on website-edge, a Cloudflare test route cannot be safely applied without first deciding the transport path.

This phase does not mutate website-edge, nginx, Cloudflare, Tailscale, Proxmox, controller/queue, workers, databases, CT101, or model endpoints.

## Previous checkpoint

Previous phase: Phase 14J-FH - Website-edge nginx static wrapper local runtime apply
Previous commit: fe0cf29
Previous tag: controller-phase-14j-fh-website-edge-nginx-static-wrapper-local-runtime-apply-2026-06-17

## Mutation scope for this phase

MUTATION_SCOPE=docs_smoke_only_cloudflare_test_route_feasibility_plan

This FI phase performs only:

- laptop repo documentation
- laptop repo smoke script creation
- commit, tag, and push

This FI phase does not mutate website-edge or Cloudflare.

## Current website-edge state from FH

WEBSITE_EDGE_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_APPLY_PASSED=yes
WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e
WEBSITE_EDGE_CHECKOUT_TAG=controller-phase-14j-fc-inspect-public-wrapper-entrypoints-and-plan-local-only-clone-smoke-2026-06-17
WEBSITE_EDGE_SPARSE_MODE=non-cone
WEBSITE_EDGE_SPARSE_SCOPE=frontend/wrapper-ui,frontend/study-ui
WEBSITE_EDGE_ACTUAL_WORKTREE_FILE_COUNT=18
WEBSITE_EDGE_NGINX_LOCAL_PORT=18080
WEBSITE_EDGE_NGINX_LISTENER_SCOPE=loopback_only
WEBSITE_EDGE_NGINX_CONFIG_TEST_BEFORE_RELOAD=passed
WEBSITE_EDGE_NGINX_RELOAD_AFTER_CONFIG_TEST=passed
WEBSITE_EDGE_NGINX_LOCAL_GET_ROOT_STATUS=200
WEBSITE_EDGE_NGINX_LOCAL_GET_APP_JS_STATUS=200
WEBSITE_EDGE_NGINX_LOCAL_GET_STYLES_CSS_STATUS=200
WEBSITE_EDGE_NGINX_LOCAL_GET_QUEUED_CHAT_CONFIG_JS_STATUS=200
WEBSITE_EDGE_SOURCE_CHECKOUT_REMAINED_CLEAN=yes
WEBSITE_EDGE_DOCKER_ABSENT=yes
WEBSITE_EDGE_CLOUDFLARED_ABSENT=yes
WEBSITE_EDGE_NODE_NPM_ABSENT=yes
WEBSITE_EDGE_CLOUDFLARE_TEST_ROUTE_PERFORMED=no
WEBSITE_EDGE_CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no

## Important feasibility note

Cloudflare cannot reach a service that is bound only to 127.0.0.1 on website-edge unless a separately approved transport is introduced.

Therefore, the next safe step is not a direct production cutover. The next safe step is either:

- a read-only Cloudflare and public-route inventory, or
- a separately approved test-route transport plan.

## Future read-only inventory target

The next safe phase should prefer read-only inspection before any Cloudflare mutation.

FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_ROUTE_MAP=yes
FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_TUNNEL_MAP=yes
FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_WORKER_ROUTE_OWNERSHIP=yes
FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_PUBLIC_HOSTNAME_PLAN=yes
FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_SANITIZED_OUTPUT_ONLY=yes
FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_NO_SECRETS_RAW_IPS_AUTH_URLS=yes

## Future test route allowed scope after separate approval

A future Cloudflare test route apply may be considered only after the transport path is explicit.

FUTURE_CLOUDFLARE_TEST_ALLOWED_TEST_HOSTNAME_ONLY=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_NO_APEX_CUTOVER=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_NO_PRODUCTION_ROUTE_REPLACEMENT=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_SANITIZED_OUTPUT_ONLY=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_ROLLBACK_PLAN_REQUIRED=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_LOCAL_WEBSITE_EDGE_HEALTH_CHECK_REQUIRED=yes
FUTURE_CLOUDFLARE_TEST_ALLOWED_NO_PROXMOX_PUBLIC_CONTROLS=yes

## Future denied scope

FUTURE_CLOUDFLARE_TEST_DENY_PRODUCTION_CUTOVER=yes
FUTURE_CLOUDFLARE_TEST_DENY_APEX_ROUTE_REPLACEMENT=yes
FUTURE_CLOUDFLARE_TEST_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes
FUTURE_CLOUDFLARE_TEST_DENY_PROXMOX_PUBLIC_EXPOSURE=yes
FUTURE_CLOUDFLARE_TEST_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_CLOUDFLARE_TEST_DENY_WORKER_START=yes
FUTURE_CLOUDFLARE_TEST_DENY_RUNTIME_ACTIVATION=yes
FUTURE_CLOUDFLARE_TEST_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_CLOUDFLARE_TEST_DENY_CT101_CALL=yes
FUTURE_CLOUDFLARE_TEST_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_CLOUDFLARE_TEST_DENY_DOCKER_INSTALL=yes
FUTURE_CLOUDFLARE_TEST_DENY_NODE_NPM_INSTALL=yes
FUTURE_CLOUDFLARE_TEST_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_CLOUDFLARE_TEST_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_CLOUDFLARE_TEST_DENY_SUBNET_ROUTES=yes
FUTURE_CLOUDFLARE_TEST_DENY_EXIT_NODE=yes
FUTURE_CLOUDFLARE_TEST_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_CLOUDFLARE_TEST_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Transport decision gates before any test-route apply

Before any Cloudflare test route apply, the project must explicitly decide and document:

- whether the test route uses an existing tunnel, a new cloudflared install, or another approved proxy path
- whether any new package install is required
- whether nginx must stay loopback-only or can listen on another private-only interface
- how rollback will remove the test route
- how production routes remain unchanged
- how public users are prevented from reaching Proxmox controls
- how secrets, raw IPs, auth URLs, and tokens stay out of terminal output
- how local website-edge nginx health is verified before Cloudflare mutation
- how post-test cleanup is verified

## Result

PHASE_14J_FI_RESULT=cloudflare_test_route_feasibility_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=read_only_cloudflare_route_and_tunnel_inventory_before_any_test_route_apply

The next phase should be read-only inventory unless the user separately approves a specific Cloudflare test-route transport plan.
