#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fe-plan-website-edge-local-loopback-static-server-smoke.md"

echo "=== Phase 14J-FE smoke: website-edge local loopback static server smoke plan ==="

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

require_marker "PHASE_14J_FE_PLAN_WEBSITE_EDGE_LOCAL_LOOPBACK_STATIC_SERVER_SMOKE"
require_marker "MUTATION_SCOPE=docs_smoke_only_local_loopback_static_server_smoke_plan"
require_marker "Previous commit: 142be68"
require_marker "WEBSITE_EDGE_SPARSE_STATIC_CHECKOUT_VERIFIED=yes"
require_marker "WEBSITE_EDGE_CHECKOUT_COMMIT=03a6b4e"
require_marker "WEBSITE_EDGE_SPARSE_MODE=non-cone"
require_marker "WEBSITE_EDGE_SPARSE_SCOPE=frontend/wrapper-ui,frontend/study-ui"
require_marker "WEBSITE_EDGE_ACTUAL_WORKTREE_FILE_COUNT=18"
require_marker "WEBSITE_EDGE_REQUIRED_WRAPPER_STATIC_FILES_PRESENT=yes"
require_marker "WEBSITE_EDGE_OPTIONAL_STUDY_STATIC_FILES_PRESENT=yes"
require_marker "WEBSITE_EDGE_SENSITIVE_FILENAME_COUNT=0"
require_marker "WEBSITE_EDGE_RUNTIME_PATH_COUNT=0"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_USE_EXISTING_SPARSE_CHECKOUT=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_TEMPORARY_PYTHON_HTTP_SERVER=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_BIND_127_0_0_1_ONLY=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_LOCAL_CURL_ONLY=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_INDEX_HTML=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_APP_JS=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_STYLES_CSS=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_VERIFY_CONFIG_JS=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_ALLOWED_STOP_TEMP_SERVER=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_NGINX_CONFIG_MUTATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_SYSTEMD_RUNTIME_CREATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARE_TEST_ROUTE=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARE_PRODUCTION_CUTOVER=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_DOCKER_INSTALL=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_CLOUDFLARED_INSTALL=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_NODE_NPM_INSTALL=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_APP_DEPLOYMENT=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_CONTROLLER_QUEUE_MIGRATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_WORKER_START=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_RUNTIME_ACTIVATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_PRODUCTION_DB_JOB_MUTATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_CT101_CALL=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_SUBNET_ROUTES=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_EXIT_NODE=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_PROXMOX_PUBLIC_CONTROLS=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes"
require_marker "FUTURE_LOOPBACK_SMOKE_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes"
require_marker "temporary server binds to 127.0.0.1 only"
require_marker "temporary server is stopped before script exit"
require_marker "PHASE_14J_FE_RESULT=local_loopback_static_server_smoke_plan_recorded"
require_marker "NEXT_SAFE_PHASE=approve_website_edge_temporary_loopback_static_server_smoke"

echo "PASS: Phase 14J-FE local loopback static server smoke plan is complete"
