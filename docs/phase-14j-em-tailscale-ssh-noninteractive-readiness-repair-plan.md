# Phase 14J-EM - Tailscale SSH Noninteractive Readiness Repair Plan

PHASE_14J_EM_TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_noninteractive_readiness_repair_plan

This phase plans the next safe diagnostic/repair path after EL verified that the configured Tailscale Proxmox target is reachable on TCP 22 but noninteractive read-only SSH exited with rc=255 and produced no sanitized stdout/stderr.

SAFE_TRAP_PATTERN=yes
NO_TRAP_EXIT=yes

No app source is mutated. No production DB rows are changed. No jobs are mutated. No controller service is restarted or reloaded. No Proxmox service is restarted or reloaded. No firewall is mutated. No ssh config is mutated. No LAN firewall TCP22 opening occurs. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run in this phase. No Proxmox remote command is executed in this phase. No GitHub branch or repository deletion occurs. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Carried-forward EL result

EL_RESULT=completed_tailscale_target_reachable_but_noninteractive_ssh_failed
CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes
CONFIGURED_TAILSCALE_TARGET_BANNER_VENDOR=Tailscale
CONFIGURED_PROXMOX_READ_ONLY_SSH_RC=255
CONFIGURED_PROXMOX_READ_ONLY_STDERR_EMPTY=yes
CONFIGURED_PROXMOX_READ_ONLY_STDOUT_EMPTY=yes
CONFIGURED_TAILSCALE_REMOTE_READ_ONLY_COMMAND_EXECUTED=no
CONFIGURED_TAILSCALE_REMOTE_AUTH_OR_COMMAND_READY=no
DIRECT_LAN_SSHD_REQUIRED=no
LAN_FIREWALL_TCP22_OPEN_REQUIRED=no
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Repair hypothesis

TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN=ready

Likely causes to distinguish next:

TAILSCALE_SSH_ACL_OR_USER_MAPPING_ISSUE=possible
CONFIGURED_SSH_TARGET_USER_MISMATCH=possible
TAILSCALE_SSH_NONINTERACTIVE_COMMAND_POLICY_ISSUE=possible
SSH_TARGET_FORMATTING_OR_OPTIONS_ISSUE=possible
AUTH_REQUIRES_INTERACTIVE_TAILSCALE_FLOW=possible
TARGET_REACHABLE_BUT_COMMAND_EXECUTION_BLOCKED=confirmed_context

## Next diagnostic boundaries

The next approved diagnostic may verify noninteractive SSH readiness using sanitized/hash-only output and short timeouts.

Allowed in the next approved diagnostic:

CHECK_CONFIGURED_PROXMOX_SSH_TARGET_PRESENT_HASH_ONLY=yes
CHECK_CONFIGURED_TARGET_TCP22_BANNER_HASH_ONLY=yes
CHECK_SSH_BATCHMODE_FAILURE_REASON_SANITIZED=yes
CHECK_SSH_VERBOSE_AUTH_STAGE_SANITIZED_LIMITED=yes
CHECK_SSH_EXIT_CODE_ONLY=yes
CHECK_NO_REMOTE_MUTATION=yes
CHECK_NO_PRODUCTION_DB_MUTATION=yes
CHECK_NO_JOB_MUTATION=yes
CHECK_NO_SERVICE_ENV_MUTATION=yes
CHECK_NO_POWER_ENDPOINT_CALL=yes
CHECK_NO_WORKER_START=yes
CHECK_NO_RUNTIME_ACTIVATION=yes

Disallowed unless separately approved later:

TAILSCALE_ACL_MUTATION=not_allowed
TAILSCALE_ADMIN_CONSOLE_CHANGE=not_allowed
PROXMOX_USER_MUTATION=not_allowed
SSH_CONFIG_MUTATION=not_allowed
FIREWALL_MUTATION=not_allowed
LAN_FIREWALL_TCP22_OPEN=not_allowed
SERVICE_ENV_MUTATION=not_allowed
POWER_ENDPOINT_CALL=not_allowed
WORKER_START=not_allowed
RUNTIME_ACTIVATION=not_allowed

## Privacy and terminal-safety rules

NO_RAW_CONFIGURED_SSH_TARGET_PRINTING=yes
HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes
REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
REQUIRE_SHORT_TIMEOUTS=yes
REQUIRE_SANITIZED_OUTPUT=yes
NO_SECRETS_PRINTED=yes
REQUIRE_SAFE_SUBSHELL_TRAP_PATTERN=yes
REQUIRE_NO_EXIT_IN_TRAP=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-en-tailscale-ssh-noninteractive-readiness-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-EN Tailscale SSH noninteractive readiness read-only diagnostics with sanitized output, hash-only configured target output, short timeouts, safe subshell trap pattern, and no exit inside trap, using only the already configured Proxmox SSH target from the controller service environment, with configured target presence/hash checks, TCP22 banner hash-only checks, limited sanitized SSH BatchMode/verbose auth-stage diagnostics, and SSH exit-code-only checks allowed, no remote mutation, no Tailscale ACL mutation, no Tailscale admin console change, no Proxmox user mutation, no Proxmox service restart/reload, no firewall mutation, no ssh config mutation, no LAN firewall TCP22 opening, no power endpoint call, no worker start, no production DB mutation, no production job mutation, no controller service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EM

APP_SOURCE_MUTATION=not_performed
PRODUCTION_DB_MUTATION=not_performed
JOB_MUTATION=not_performed
CONTROLLER_SERVICE_RESTART_RELOAD=not_performed
PROXMOX_SERVICE_RESTART_RELOAD=not_performed
FIREWALL_MUTATION=not_performed
SSH_CONFIG_MUTATION=not_performed
LAN_FIREWALL_TCP22_OPEN=not_performed
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
HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes
DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
NO_SECRETS_PRINTED=yes

## Result

TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN_RESULT=ready_for_read_only_diagnostics

NEXT_SAFE_PHASE=tailscale_ssh_noninteractive_readiness_read_only_diagnostics_requires_approval
