#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fg-plan-nginx-static-wrapper-local-runtime-without-cloudflare-cutover.md"

echo "=== Phase 14J-FG smoke: nginx static wrapper local runtime plan ==="

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

require_marker "PHASE_14J_FG_PLAN_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_WITHOUT_CLOUDFLARE_CUTOVER"
require_marker "MUTATION_SCOPE=docs_smoke_only_nginx_static_wrapper_local_runtime_plan"
require_marker "Previous commit: 4868f05"
require_marker "WEBSITE_EDGE_LOOPBACK_STATIC_SERVER_SMOKE_PASSED=yes"
require_marker "WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e"
require_marker "WEBSITE_EDGE_SPARSE_MODE=non-cone"
require_marker "WEBSITE_EDGE_SPARSE_SCOPE=frontend/wrapper-ui,frontend/study-ui"
require_marker "WEBSITE_EDGE_ACTUAL_WORKTREE_FILE_COUNT=18"
require_marker "WEBSITE_EDGE_TEMPORARY_SERVER_STOPPED_BEFORE_EXIT=yes"
require_marker "WEBSITE_EDGE_CHECKOUT_REMAINED_CLEAN_AFTER_LOOPBACK_SMOKE=yes"
require_marker "WEBSITE_EDGE_DOCKER_ABSENT=yes"
require_marker "WEBSITE_EDGE_CLOUDFLARED_ABSENT=yes"
require_marker "WEBSITE_EDGE_NODE_NPM_ABSENT=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_USE_EXISTING_SPARSE_CHECKOUT=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_COPY_WRAPPER_STATIC_FILES=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_CREATE_NONSECRET_DOCROOT=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_CREATE_NGINX_LOCAL_SITE_CONFIG=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_NGINX_CONFIG_TEST=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_RELOAD_NGINX_ONLY_AFTER_CONFIG_TEST=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_LOCAL_CURL_ONLY=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_INDEX_HTML=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_APP_JS=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_STYLES_CSS=yes"
require_marker "FUTURE_NGINX_LOCAL_ALLOWED_VERIFY_CONFIG_JS=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_CLOUDFLARE_TEST_ROUTE=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_CLOUDFLARE_PRODUCTION_CUTOVER=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_CLOUDFLARED_INSTALL=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_DOCKER_INSTALL=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_NODE_NPM_INSTALL=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_SYSTEMD_APP_RUNTIME_CREATION=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_CONTROLLER_QUEUE_MIGRATION=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_WORKER_START=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_RUNTIME_ACTIVATION=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_PRODUCTION_DB_JOB_MUTATION=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_CT101_CALL=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_SUBNET_ROUTES=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_EXIT_NODE=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_PROXMOX_PUBLIC_CONTROLS=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes"
require_marker "FUTURE_NGINX_LOCAL_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes"
require_marker "rollback path"
require_marker "PHASE_14J_FG_RESULT=nginx_static_wrapper_local_runtime_plan_recorded"
require_marker "NEXT_SAFE_PHASE=approve_website_edge_nginx_static_wrapper_local_runtime_apply_without_cloudflare_cutover"

echo "PASS: Phase 14J-FG nginx static wrapper local runtime plan is complete"
