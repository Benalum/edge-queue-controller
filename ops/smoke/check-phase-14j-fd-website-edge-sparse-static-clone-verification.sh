#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fd-website-edge-sparse-static-clone-verification.md"

echo "=== Phase 14J-FD smoke: website-edge sparse static clone verification record ==="

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

require_marker "PHASE_14J_FD_WEBSITE_EDGE_SPARSE_STATIC_CLONE_VERIFICATION"
require_marker "Previous commit: 03a6b4e"
require_marker "Initial FD attempt result"
require_marker "First FD repair result"
require_marker "Successful FD repair 2 result"
require_marker "sparse_mode=non-cone"
require_marker "/frontend/wrapper-ui/**"
require_marker "/frontend/study-ui/**"
require_marker "hostname=website-edge"
require_marker "os_version=26.04"
require_marker "head_now=03a6b4e"
require_marker "tag_now=03a6b4e"
require_marker "git_status_short=<clean>"
require_marker "actual_worktree_file_count=18"
require_marker "PASS: actual filesystem worktree limited to frontend/wrapper-ui and frontend/study-ui"
require_marker "PASS: required static file present: frontend/wrapper-ui/index.html"
require_marker "PASS: required static file present: frontend/wrapper-ui/app.js"
require_marker "PASS: required static file present: frontend/wrapper-ui/styles.css"
require_marker "PASS: required static file present: frontend/wrapper-ui/queued_chat_config.js"
require_marker "PASS: required static file present: frontend/wrapper-ui/queued_chat_status.js"
require_marker "PASS: required static file present: frontend/wrapper-ui/router_shadow_read_stub.js"
require_marker "PASS: optional study static file present: frontend/study-ui/index.html"
require_marker "PASS: optional study static file present: frontend/study-ui/app.js"
require_marker "PASS: optional study static file present: frontend/study-ui/styles.css"
require_marker "PASS: optional study static file present: frontend/study-ui/study-content.partial.html"
require_marker "PASS: optional study static file present: frontend/study-ui/study-dashboard.partial.html"
require_marker "PASS: wrapper index references app.js"
require_marker "PASS: wrapper index references styles.css"
require_marker "PASS: wrapper index references queued_chat_config.js"
require_marker "sensitive_filename_count=0"
require_marker "runtime_path_count=0"
require_marker "PASS: command absent after fd: docker"
require_marker "PASS: command absent after fd: cloudflared"
require_marker "PASS: command absent after fd: node"
require_marker "PASS: command absent after fd: npm"
require_marker "app_deployment_performed=no"
require_marker "nginx_config_mutation_performed=no"
require_marker "systemd_runtime_creation_performed=no"
require_marker "cloudflare_test_route_performed=no"
require_marker "cloudflare_production_cutover_performed=no"
require_marker "docker_install_performed=no"
require_marker "cloudflared_install_performed=no"
require_marker "node_npm_install_performed=no"
require_marker "controller_queue_migration_performed=no"
require_marker "worker_start_performed=no"
require_marker "runtime_activation_performed=no"
require_marker "production_db_job_mutation_performed=no"
require_marker "ct101_call_performed=no"
require_marker "model_ollama_endpoint_call_performed=no"
require_marker "tailscale_acl_grants_tag_mutation_performed=no"
require_marker "tailscale_ssh_mode_enablement_performed=no"
require_marker "phase_14j_ag_apply_wrapper_rerun_performed=no"
require_marker "PHASE_14J_FD_RESULT=passed"
require_marker "PHASE_14J_FD_RESULT=website_edge_sparse_static_clone_verification_recorded"
require_marker "NEXT_SAFE_PHASE=plan_local_loopback_static_server_smoke_without_nginx_or_cloudflare"

echo "PASS: Phase 14J-FD sparse static clone verification record is complete"
