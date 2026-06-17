# Phase 14J-DY - Tailscale SSH vs Proxmox sshd Target Plan

PHASE_14J_DY_TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_vs_proxmox_sshd_target_plan

This phase plans the decision work after Phase 14J-DX narrowed the controller power dry-run failure to Tailscale SSH or pre-auth policy timeout after host-key exchange.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=c26e91e
- START_TAG=controller-phase-14j-dx-ssh-handshake-or-hostkey-timeout-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DX finding carried forward

- SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed
- DX_NARROWED_ROOT_CAUSE_AREA=tailscale_ssh_or_pre_auth_policy_timeout_after_hostkey
- SSH_BANNER_PREFIX=SSH-2.0
- SSH_BANNER_VENDOR_SANITIZED=Tailscale
- SSH_KEYSCAN_RC=0
- SSH_HOSTKEY_VERIFICATION_FAILURE=no
- SSH_POST_HOSTKEY_PRE_AUTH_TIMEOUT=yes
- SSH_REMOTE_COMMAND_EXECUTION_REACHED=no
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Planning objective

TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN=ready_for_read_only_target_decision_diagnostics

The next diagnostic phase should determine whether the configured controller Proxmox SSH target is using Tailscale SSH and whether that is appropriate for noninteractive controller automation.

The target decision must distinguish:

1. Tailscale SSH endpoint with ACL/policy approval requirements.
2. Direct Proxmox OpenSSH daemon reachable over Tailscale IP/DNS or LAN/VPN address.
3. Host target resolving to the Tailscale SSH service instead of Proxmox sshd.
4. Whether noninteractive BatchMode controller automation should use Tailscale SSH or direct sshd.
5. Whether the service environment should eventually change only the SSH target, not the power logic.
6. Whether a later source patch is needed to handle Tailscale SSH failures gracefully.

## Allowed diagnostics for next phase

The next phase may perform read-only, sanitized, short-timeout diagnostics only:

- CHECK_TAILSCALE_SSH_STATUS_REDACTED=yes
- CHECK_TAILSCALE_SSH_POLICY_HINTS_REDACTED=yes
- CHECK_DIRECT_PROXMOX_SSHD_CANDIDATE_TARGETS_REDACTED=yes
- CHECK_TCP_22_BANNER_VENDOR_FOR_CANDIDATES=yes
- CHECK_SSH_KEYSCAN_HASH_ONLY_FOR_CANDIDATES=yes
- CHECK_CONTROLLER_ENV_TARGET_HASH_ONLY=yes
- CHECK_NO_RAW_SSH_TARGET_OR_KEY_PATH_OUTPUT=yes
- CHECK_NO_FULL_SYSTEMD_ENVIRONMENT_OUTPUT=yes

## Strict blocks for next phase

- ALLOW_POWER_ENDPOINT_CALL=no
- ALLOW_EXECUTE_POWER_ENDPOINT_CALL=no
- ALLOW_WORKER_START=no
- ALLOW_PRODUCTION_DB_MUTATION=no
- ALLOW_PRODUCTION_JOB_MUTATION=no
- ALLOW_SERVICE_RESTART_RELOAD=no
- ALLOW_CT101_CALL=no
- ALLOW_MODEL_OLLAMA_CALL=no
- ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no
- ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no
- ALLOW_RUNTIME_ACTIVATION=no
- ALLOW_APP_SOURCE_MUTATION=no
- ALLOW_GITHUB_BRANCH_OR_REPO_DELETE=no
- ALLOW_RAW_SECRET_OR_TARGET_OUTPUT=no
- REQUIRE_SANITIZED_OUTPUT=yes
- REQUIRE_NO_SECRET_PRINTING=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_HASH_ONLY_HOSTKEY_OUTPUT=yes

## Decision

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_DECISION_REQUIRED=yes

The guarded worker start path remains blocked until the correct noninteractive SSH target path is selected and verified by a later dry-run.

## Next phase

NEXT_PHASE_NAME=phase-14j-dz-tailscale-ssh-vs-proxmox-sshd-target-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-DZ Tailscale SSH vs Proxmox sshd target read-only diagnostics with sanitized output and short timeouts, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DY

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN_RESULT=ready_for_explicit_read_only_diagnostics

NEXT_SAFE_PHASE=tailscale_ssh_vs_proxmox_sshd_target_read_only_diagnostics_requires_approval
