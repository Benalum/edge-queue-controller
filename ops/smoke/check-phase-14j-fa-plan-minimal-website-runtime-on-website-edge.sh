#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-fa-plan-minimal-website-runtime-on-website-edge"
DOC="docs/${PHASE}.md"

echo "=== Phase 14J-FA smoke: plan minimal website runtime on website-edge ==="

test -f "$DOC"
echo "PASS: FA doc exists"

for marker in \
  "PHASE_14J_FA_PLAN_MINIMAL_WEBSITE_RUNTIME_ON_WEBSITE_EDGE" \
  "MUTATION_SCOPE=docs_smoke_only_minimal_website_runtime_plan" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "PHASE_14J_EZ_RESULT=website_vm_reinstall_access_bootstrap_and_post_install_baseline_recorded" \
  "WEBSITE_EDGE_RUNTIME_GOAL=public_wrapper_static_edge_first" \
  "WEBSITE_EDGE_RUNTIME_FIRST_STEP=minimal_static_wrapper_runtime" \
  "WEBSITE_EDGE_RUNTIME_DEPLOYMENT_MODE=clone_repo_then_run_public_wrapper_only_after_approval" \
  "WEBSITE_EDGE_RUNTIME_PRODUCTION_CUTOVER_ALLOWED_IN_FA=no" \
  "INSTALL_CANDIDATE_QEMU_GUEST_AGENT=yes" \
  "INSTALL_CANDIDATE_PYTHON3_VENV=yes" \
  "INSTALL_CANDIDATE_NGINX=yes" \
  "INSTALL_CANDIDATE_DOCKER=no_for_initial_static_wrapper_runtime" \
  "WEBSITE_EDGE_RUN_FULL_CONTROLLER=no" \
  "WEBSITE_EDGE_RUN_QUEUE=no" \
  "WEBSITE_EDGE_RUN_WORKERS=no" \
  "WEBSITE_EDGE_RUN_PROXMOX_MANAGEMENT=no" \
  "WEBSITE_EDGE_RUN_MODEL_ENDPOINTS=no" \
  "WEBSITE_EDGE_PUBLIC_USERS_CAN_CONTROL_INFRASTRUCTURE=no" \
  "PLAN_STEP_1_INSTALL_BASELINE_PACKAGES_AFTER_APPROVAL=yes" \
  "PLAN_STEP_2_CLONE_REPO_AFTER_APPROVAL=yes" \
  "PLAN_STEP_4_LOCALHOST_SMOKE_ONLY=yes" \
  "PLAN_STEP_5_TEST_CLOUDFLARE_ROUTE_ONLY_AFTER_LOCAL_SMOKE=yes" \
  "PLAN_STEP_6_PRODUCTION_CLOUDFLARE_CUTOVER_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "REQUIRE_APPROVAL_BEFORE_PACKAGE_INSTALL=yes" \
  "REQUIRE_NO_CLOUDFLARE_CUTOVER_DURING_PACKAGE_INSTALL=yes" \
  "REQUIRE_NO_APP_DEPLOYMENT_DURING_PACKAGE_INSTALL=yes" \
  "REQUIRE_NO_CONTROLLER_QUEUE_MIGRATION=yes" \
  "REQUIRE_NO_WORKER_START=yes" \
  "REQUIRE_NO_RUNTIME_ACTIVATION=yes" \
  "REQUIRE_NO_PRODUCTION_DB_JOB_MUTATION=yes" \
  "REQUIRE_NO_TAILSCALE_SSH_MODE_ENABLEMENT=yes" \
  "VM_MUTATION_PERFORMED=no" \
  "PACKAGE_INSTALL_PERFORMED=no" \
  "GIT_CLONE_PERFORMED=no" \
  "APP_DEPLOYMENT_PERFORMED=no" \
  "CLOUDFLARE_CUTOVER_PERFORMED=no" \
  "TAILSCALE_ACL_GRANTS_TAG_MUTATION_PERFORMED=no" \
  "WORKER_START_PERFORMED=no" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "PRODUCTION_DB_JOB_MUTATION_PERFORMED=no" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "PHASE_14J_FA_RESULT=minimal_website_runtime_plan_recorded" \
  "NEXT_SAFE_PHASE=approve_install_baseline_packages_on_website_edge"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo "PASS: Phase 14J-FA minimal website runtime plan smoke passed"
