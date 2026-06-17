#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fc-inspect-public-wrapper-entrypoints-and-plan-local-only-clone-smoke.md"

echo "=== Phase 14J-FC smoke: public wrapper entrypoint inspection and clone-smoke plan ==="

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

require_marker "PHASE_14J_FC_INSPECT_PUBLIC_WRAPPER_ENTRYPOINTS_AND_PLAN_LOCAL_ONLY_CLONE_SMOKE"
require_marker "MUTATION_SCOPE=docs_smoke_only_public_wrapper_entrypoint_inspection_plan"
require_marker "WEBSITE_EDGE_BASELINE_PACKAGES_INSTALLED=yes"
require_marker "WEBSITE_EDGE_QEMU_GUEST_AGENT_ACTIVE=yes"
require_marker "WEBSITE_EDGE_PYTHON3_VENV_INSTALLED=yes"
require_marker "WEBSITE_EDGE_NGINX_ACTIVE=yes"
require_marker "WEBSITE_EDGE_NGINX_LOCAL_HTTP_200=yes"
require_marker "WEBSITE_EDGE_RUNTIME_GOAL=public_wrapper_static_edge_first"
require_marker "WEBSITE_EDGE_MUST_NOT_RUN_FULL_CONTROLLER=yes"
require_marker "WEBSITE_EDGE_MUST_NOT_RUN_QUEUE=yes"
require_marker "WEBSITE_EDGE_MUST_NOT_RUN_WORKERS=yes"
require_marker "WEBSITE_EDGE_MUST_NOT_RUN_MODEL_ENDPOINTS=yes"
require_marker "WEBSITE_EDGE_MUST_NOT_EXPOSE_PROXMOX_OR_POWER_CONTROLS=yes"
require_marker "WEBSITE_EDGE_MUTATION_PERFORMED=no"
require_marker "PROXMOX_MUTATION_PERFORMED=no"
require_marker "APP_CLONE_PERFORMED=no"
require_marker "APP_DEPLOYMENT_PERFORMED=no"
require_marker "NGINX_CONFIG_MUTATION_PERFORMED=no"
require_marker "CLOUDFLARE_TEST_ROUTE_PERFORMED=no"
require_marker "CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no"
require_marker "DOCKER_INSTALL_PERFORMED=no"
require_marker "CLOUDFLARED_INSTALL_PERFORMED=no"
require_marker "NODE_NPM_INSTALL_PERFORMED=no"
require_marker "TAILSCALE_ACL_GRANTS_TAG_MUTATION_PERFORMED=no"
require_marker "TAILSCALE_SSH_MODE_ENABLEMENT_PERFORMED=no"
require_marker "CONTROLLER_QUEUE_MIGRATION_PERFORMED=no"
require_marker "WORKER_START_PERFORMED=no"
require_marker "RUNTIME_ACTIVATION_PERFORMED=no"
require_marker "PRODUCTION_DB_JOB_MUTATION_PERFORMED=no"
require_marker "CT101_CALL_PERFORMED=no"
require_marker "MODEL_OLLAMA_ENDPOINT_CALL_PERFORMED=no"
require_marker "PHASE_14J_AG_APPLY_WRAPPER_RERUN_PERFORMED=no"
require_marker "FUTURE_APPROVAL_REQUIRED_BEFORE_WEBSITE_EDGE_CLONE=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_CLOUDFLARE_CUTOVER=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_CLOUDFLARED_INSTALL=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_NGINX_CONFIG_MUTATION=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_CONTROLLER_QUEUE_MIGRATION=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_WORKER_START=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_RUNTIME_ACTIVATION=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_PRODUCTION_DB_JOB_MUTATION=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_CT101_MODEL_CALLS=yes"
require_marker "FUTURE_CLONE_PHASE_DENY_TAILSCALE_POLICY_MUTATION=yes"
require_marker "Generated sanitized read-only inventory"
require_marker "PHASE_14J_FC_RESULT=public_wrapper_entrypoint_inspection_and_local_clone_smoke_plan_recorded"
require_marker "NEXT_SAFE_PHASE=approve_website_edge_repo_clone_for_local_only_public_wrapper_smoke"

echo "PASS: Phase 14J-FC inspection/plan record is complete"
