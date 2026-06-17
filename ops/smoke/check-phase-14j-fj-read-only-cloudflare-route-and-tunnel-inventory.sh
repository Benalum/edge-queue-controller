#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fj-read-only-cloudflare-route-and-tunnel-inventory.md"

echo "=== Phase 14J-FJ smoke: read-only Cloudflare route and tunnel inventory ==="

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

require_marker "PHASE_14J_FJ_READ_ONLY_CLOUDFLARE_ROUTE_AND_TUNNEL_INVENTORY"
require_marker "Previous commit: beb988d"
require_marker "MUTATION_SCOPE=laptop_repo_read_only_cloudflare_public_route_inventory_docs_smoke_commit_tag_push"
require_marker "SANITIZED_OUTPUT_ONLY=yes"
require_marker "SECRETS_TOKENS_RAW_IPS_AUTH_URLS_REDACTED=yes"
require_marker "REMOTE_CLOUDFLARE_API_CALL_PERFORMED=no"
require_marker "CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no"
require_marker "CLOUDFLARE_TEST_ROUTE_APPLY_PERFORMED=no"
require_marker "CLOUDFLARED_INSTALL_PERFORMED=no"
require_marker "CLOUDFLARE_EDGE_PUBLIC_PROXY_PRESENT="
require_marker "CLOUDFLARE_WORKER_SRC_PRESENT="
require_marker "PUBLIC_GATEWAY_PRESENT="
require_marker "PUBLIC_ROUTE_DOCS_PRESENT="
require_marker "WRAPPER_STATIC_HEADERS_PRESENT="
require_marker "WRAPPER_STATIC_REDIRECTS_PRESENT="
require_marker "CLOUDFLARED_PRESENT="
require_marker "WRANGLER_PRESENT="
require_marker "LOCAL_CLOUDFLARED_CONFIG_CONTENT_READ=no"
require_marker "FUTURE_TEST_ROUTE_GATE_TRANSPORT_PATH_EXPLICIT=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_TEST_HOSTNAME_ONLY=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_NO_APEX_CUTOVER=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_NO_PRODUCTION_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_ROLLBACK_PLAN_REQUIRED=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_SANITIZED_OUTPUT_ONLY=yes"
require_marker "FUTURE_TEST_ROUTE_GATE_NO_PROXMOX_PUBLIC_CONTROLS=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_PRODUCTION_CUTOVER=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_APEX_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_PROXMOX_PUBLIC_EXPOSURE=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_CONTROLLER_QUEUE_MIGRATION=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_WORKER_START=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_RUNTIME_ACTIVATION=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_PRODUCTION_DB_JOB_MUTATION=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_CT101_CALL=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_DOCKER_INSTALL=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_NODE_NPM_INSTALL=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_SUBNET_ROUTES=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_EXIT_NODE=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes"
require_marker "FUTURE_TEST_ROUTE_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes"
require_marker "PHASE_14J_FJ_RESULT=read_only_cloudflare_route_and_tunnel_inventory_recorded"
require_marker "NEXT_SAFE_PHASE=plan_explicit_cloudflare_test_route_transport_without_production_cutover"

echo "PASS: Phase 14J-FJ read-only Cloudflare inventory record is complete"
