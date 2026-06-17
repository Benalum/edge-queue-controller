# Phase 14J-EO - Tailscale SSH Auth Policy Repair Plan

PHASE_14J_EO_TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_auth_policy_repair_plan

This phase plans the safe repair path after EN confirmed that the configured Tailscale SSH management target is network-reachable but noninteractive SSH is blocked by Tailscale SSH additional authentication/check behavior.

SAFE_TRAP_PATTERN=yes
NO_TRAP_EXIT=yes

No app source is mutated. No production DB rows are changed. No jobs are mutated. No controller service is restarted or reloaded. No Proxmox service is restarted or reloaded. No firewall is mutated. No ssh config is mutated. No LAN firewall TCP22 opening occurs. No Tailscale ACL is mutated. No Tailscale admin console change occurs. No Proxmox user is mutated. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run in this phase. No Proxmox remote command is executed in this phase. No GitHub branch or repository deletion occurs. No full systemd environment is printed. No raw SSH target or raw key path is printed. No raw Tailscale auth URL is recorded.

## Carried-forward EN result

EN_RESULT=completed_tailscale_auth_or_acl_additional_check_required
CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes
CONFIGURED_TAILSCALE_TARGET_BANNER_VENDOR=Tailscale
SSH_CONFIG_EXPANSION_WORKS=yes
NONINTERACTIVE_SSH_READY=no
REMOTE_COMMAND_EXECUTED=no
TAILSCALE_AUTH_OR_ACL_ISSUE_CONFIRMED=yes
TAILSCALE_ADDITIONAL_CHECK_REQUIRED=yes
DIRECT_LAN_SSHD_REQUIRED=no
LAN_FIREWALL_TCP22_OPEN_REQUIRED=no
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Current official-docs interpretation

OFFICIAL_TAILSCALE_DOCS_REVIEWED_FOR_EO=yes
OFFICIAL_TAILSCALE_SSH_CHECK_MODE_REAUTH_REQUIRED=yes
OFFICIAL_TAILSCALE_SSH_CHECK_MODE_USES_SIGNIN_URL=yes
OFFICIAL_TAILSCALE_SSH_CHECK_MODE_CONTROLLED_BY_SSH_POLICY_ACTION_CHECK=yes
OFFICIAL_TAILSCALE_SSH_CHECK_MODE_OPTIONAL_NOT_DEFAULT=yes
OFFICIAL_TAILSCALE_CHECK_MODE_CAN_AFFECT_AUTOMATION=yes
OFFICIAL_TAILSCALE_SECURITY_BEST_PRACTICE_CHECK_MODE_FOR_HIGH_RISK_SSH=yes

Interpretation: the controller can reach Tailscale SSH, but the current SSH policy/auth path requires an interactive additional check. That is incompatible with unattended automation unless a carefully scoped policy path is created or a different management path is chosen.

## Repair options to plan, not apply

TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN=ready

Possible repair paths:

1. Keep current check-mode behavior and require manual admin confirmation before any Proxmox automation.
   - SECURITY_POSTURE=maximal_manual_control
   - AUTOMATION_READY=no
   - RUNTIME_WORKER_ACTIVATION_BLOCKED=yes

2. Add a narrowly scoped Tailscale SSH policy path for controller-to-Proxmox automation that does not require interactive check mode.
   - SECURITY_POSTURE=controlled_automation
   - REQUIRE_OFFICIAL_TAILSCALE_POLICY_REVIEW=yes
   - REQUIRE_TAILSCALE_ADMIN_CONSOLE_CHANGE_APPROVAL=yes
   - REQUIRE_SOURCE_AND_DESTINATION_NARROWING=yes
   - REQUIRE_USER_NARROWING=yes
   - REQUIRE_NO_WILDCARD_ROOT_ACCESS=yes
   - REQUIRE_ROLLBACK_PLAN=yes

3. Create a dedicated automation identity/tag/device route for controller-to-Proxmox management.
   - SECURITY_POSTURE=preferred_for_automation_if_supported
   - REQUIRE_TAGGED_DEVICE_OR_GROUP_REVIEW=yes
   - REQUIRE_POLICY_SCOPE_TO_CONTROLLER_AND_PROXMOX=yes
   - REQUIRE_SEPARATION_FROM_HUMAN_ADMIN_ACCESS=yes
   - REQUIRE_AUDIT_TRAIL=yes

4. Use standard OpenSSH over Tailscale IP instead of Tailscale SSH, while preserving LAN firewall closure.
   - SECURITY_POSTURE=separate_key_based_automation_path
   - REQUIRE_PROXMOX_OPENSSH_READINESS_REVIEW=yes
   - REQUIRE_KEY_MANAGEMENT_PLAN=yes
   - REQUIRE_NO_LAN_TCP22_OPEN=yes
   - REQUIRE_NO_FIREWALL_WEAKENING=yes

## Recommended next direction

EO_RECOMMENDATION=prepare_policy_candidate_without_applying

Preferred near-term path: create a candidate policy/design document for a narrowly scoped noninteractive management path, then require explicit user/admin approval before any Tailscale policy, Proxmox user, SSH config, or service environment mutation.

Do not open LAN TCP22. Do not weaken Proxmox firewall. Do not change Tailscale ACLs in this phase. Do not change controller service environment in this phase.

## Required future safety gates before any repair is applied

Before any operational repair:

REQUIRE_EXPLICIT_TAILSCALE_ADMIN_APPROVAL=yes
REQUIRE_EXPLICIT_POLICY_DIFF_REVIEW=yes
REQUIRE_EXPLICIT_ROLLBACK_PLAN=yes
REQUIRE_EXPLICIT_NO_LAN_FIREWALL_OPEN_CONFIRMATION=yes
REQUIRE_EXPLICIT_NO_WILDCARD_ROOT_CONFIRMATION=yes
REQUIRE_SANITIZED_OUTPUT_ONLY=yes
REQUIRE_HASH_ONLY_TARGET_OUTPUT=yes
REQUIRE_SAFE_SUBSHELL_TRAP_PATTERN=yes
REQUIRE_NO_EXIT_IN_TRAP=yes
REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
REQUIRE_NO_RAW_TAILSCALE_AUTH_URL_RECORDING=yes
REQUIRE_NO_RERUN_14J_AG_APPLY_WRAPPER=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-ep-tailscale-ssh-auth-policy-candidate-design

The next phase should be docs/smoke-only candidate design. It should not mutate Tailscale ACLs, Tailscale admin settings, Proxmox users, SSH config, firewall, controller service environment, DB, jobs, workers, or runtime.

## Boundaries preserved by EO

APP_SOURCE_MUTATION=not_performed
PRODUCTION_DB_MUTATION=not_performed
JOB_MUTATION=not_performed
CONTROLLER_SERVICE_RESTART_RELOAD=not_performed
PROXMOX_SERVICE_RESTART_RELOAD=not_performed
FIREWALL_MUTATION=not_performed
SSH_CONFIG_MUTATION=not_performed
LAN_FIREWALL_TCP22_OPEN=not_performed
TAILSCALE_ACL_MUTATION=not_performed
TAILSCALE_ADMIN_CONSOLE_CHANGE=not_performed
PROXMOX_USER_MUTATION=not_performed
CT101_CALL=not_performed
MODEL_OLLAMA_CALL=not_performed
POWER_ENDPOINT_CALL=not_performed
WORKER_START_PERFORMED=no
SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
PERSISTENT_LANE_WORKER_STARTUP=not_performed
RUNTIME_ACTIVATION=not_performed
SERVICE_ENV_MUTATION=not_performed
PROXMOX_SSH_CALL=not_performed
PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
GITHUB_BRANCH_OR_REPO_DELETE=not_performed
FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
RAW_SSH_TARGET_PRINTING=not_performed
RAW_KEY_PATH_PRINTING=not_performed
RAW_TAILSCALE_AUTH_URL_RECORDING=not_performed
HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes
DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
NO_SECRETS_PRINTED=yes

## Result

TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN_RESULT=ready_for_policy_candidate_design

NEXT_SAFE_PHASE=tailscale_ssh_auth_policy_candidate_design
