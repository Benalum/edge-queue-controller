#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fi-plan-cloudflare-test-route-feasibility-without-production-cutover.md"

echo "=== Phase 14J-FI smoke: Cloudflare test-route feasibility plan ==="

test -f "$DOC"

require_marker() {
  local marker="$1"
  if grep -Fq -- "$marker" "$DOC"; then
    echo "PASS: marker present: $marker"
  else
    echo "FAIL: marker missing: $marker" >&2
    exit 1
  fi
}

require_marker "PHASE_14J_FI_PLAN_CLOUDFLARE_TEST_ROUTE_FEASIBILITY_WITHOUT_PRODUCTION_CUTOVER"
require_marker "MUTATION_SCOPE=docs_smoke_only_cloudflare_test_route_feasibility_plan"
require_marker "Previous commit: fe0cf29"
require_marker "WEBSITE_EDGE_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_APPLY_PASSED=yes"
require_marker "WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_PORT=18080"
require_marker "WEBSITE_EDGE_NGINX_LISTENER_SCOPE=loopback_only"
require_marker "WEBSITE_EDGE_NGINX_CONFIG_TEST_BEFORE_RELOAD=passed"
require_marker "WEBSITE_EDGE_NGINX_RELOAD_AFTER_CONFIG_TEST=passed"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_GET_ROOT_STATUS=200"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_GET_APP_JS_STATUS=200"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_GET_STYLES_CSS_STATUS=200"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_GET_QUEUED_CHAT_CONFIG_JS_STATUS=200"
require_marker "WEBSITE_EDGE_SOURCE_CHECKOUT_REMAINED_CLEAN=yes"
require_marker "WEBSITE_EDGE_DOCKER_ABSENT=yes"
require_marker "WEBSITE_EDGE_CLOUDFLARED_ABSENT=yes"
require_marker "WEBSITE_EDGE_NODE_NPM_ABSENT=yes"
require_marker "WEBSITE_EDGE_CLOUDFLARE_TEST_ROUTE_PERFORMED=no"
require_marker "WEBSITE_EDGE_CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no"
require_marker "Cloudflare cannot reach a service that is bound only to 127.0.0.1 on website-edge"
require_marker "FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_ROUTE_MAP=yes"
require_marker "FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_READ_ONLY_TUNNEL_MAP=yes"
require_marker "FUTURE_CLOUDFLARE_INVENTORY_ALLOWED_SANITIZED_OUTPUT_ONLY=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_ALLOWED_TEST_HOSTNAME_ONLY=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_ALLOWED_NO_APEX_CUTOVER=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_ALLOWED_NO_PRODUCTION_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_ALLOWED_ROLLBACK_PLAN_REQUIRED=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_PRODUCTION_CUTOVER=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_APEX_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_PROXMOX_PUBLIC_EXPOSURE=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_CONTROLLER_QUEUE_MIGRATION=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_WORKER_START=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_RUNTIME_ACTIVATION=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_PRODUCTION_DB_JOB_MUTATION=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_CT101_CALL=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_DOCKER_INSTALL=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_NODE_NPM_INSTALL=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_SUBNET_ROUTES=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_EXIT_NODE=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes"
require_marker "FUTURE_CLOUDFLARE_TEST_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes"
require_marker "Transport decision gates before any test-route apply"
require_marker "PHASE_14J_FI_RESULT=cloudflare_test_route_feasibility_plan_recorded"
require_marker "NEXT_SAFE_PHASE=read_only_cloudflare_route_and_tunnel_inventory_before_any_test_route_apply"

echo "PASS: Phase 14J-FI Cloudflare test-route feasibility plan is complete"
