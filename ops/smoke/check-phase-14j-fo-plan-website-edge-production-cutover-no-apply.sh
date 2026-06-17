#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fo-plan-website-edge-production-cutover-no-apply.md"

echo "=== Phase 14J-FO smoke: website-edge production cutover plan only ==="

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

require_marker "PHASE_14J_FO_PLAN_WEBSITE_EDGE_PRODUCTION_CUTOVER_NO_APPLY"
require_marker "Previous commit: ab6aac3"
require_marker "PRODUCTION_CUTOVER_STATUS=not_performed"
require_marker "APEX_ROOT_ROUTE_REPLACEMENT_STATUS=not_performed"
require_marker "PRIMARY_PUBLIC_ROUTE_REPLACEMENT_STATUS=not_performed"
require_marker "TEMPORARY_TEST_HOSTNAME_STATUS=active_and_smoked"
require_marker "website-edge VM 200 serves the static wrapper locally through nginx on loopback port 18080"
require_marker "cloudflared.service is active, running, and enabled"
require_marker "cloudflared.service uses --no-autoupdate"
require_marker "temporary hostname website-edge-test.alexhartel.com passed public smoke"
require_marker "production root contains expected wrapper markers"
require_marker "production /app.js returns 200 and exact hash matches website-edge local file"
require_marker "production /styles.css returns 200 and exact hash matches website-edge local file"
require_marker "production /queued_chat_config.js returns 200 and exact hash matches website-edge local file"
require_marker "cloudflare_global_api_key_use=no"
require_marker "broad_cloudflare_account_token_use=no"
require_marker "cloudflare_secret_printing=no"
require_marker "token_in_apc_last_output=no"
require_marker "token_in_chatgpt=no"
require_marker "token_in_source_files=no"
require_marker "apex_root_cutover_without_explicit_apply_approval=no"
require_marker "primary_public_route_replacement_without_explicit_apply_approval=no"
require_marker "proxmox_public_exposure=no"
require_marker "nginx_config_mutation=no"
require_marker "docker_install=no"
require_marker "node_npm_install=no"
require_marker "tailscale_acl_grants_tag_mutation=no"
require_marker "tailscale_ssh_mode_enablement=no"
require_marker "subnet_routes=no"
require_marker "exit_node=no"
require_marker "controller_queue_migration=no"
require_marker "worker_start=no"
require_marker "production_db_job_mutation=no"
require_marker "ct101_call=no"
require_marker "model_ollama_endpoint_call=no"
require_marker "phase_14j_ag_apply_wrapper_rerun=no"
require_marker "PHASE_14J_FO_RESULT=production_cutover_plan_recorded_no_apply"
require_marker "CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no"
require_marker "PRODUCTION_CUTOVER_PERFORMED=no"
require_marker "WEBSITE_EDGE_MUTATION_PERFORMED=no"
require_marker "TOKEN_USED=no"
require_marker "TOKEN_PRINTED=no"
require_marker "TEMPORARY_TEST_HOSTNAME_LEFT_ACTIVE=yes"
require_marker "NEXT_SAFE_PHASE=explicit_approval_required_for_website_edge_production_cutover_apply_or_source_refresh_new_chat_handoff"

echo "PASS: Phase 14J-FO production cutover plan only is complete"
