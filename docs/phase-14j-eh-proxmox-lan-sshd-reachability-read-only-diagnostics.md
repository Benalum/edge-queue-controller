# Phase 14J-EH - Proxmox LAN sshd Reachability Read-Only Diagnostics

PHASE_14J_EH_PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_lan_sshd_reachability_result

This phase records the approved Proxmox LAN sshd reachability read-only diagnostics.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment was printed. No raw SSH target or raw key path is recorded. Target and host-key output remain hash-only.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=db7de5c
- START_TAG=controller-phase-14j-eg-proxmox-lan-sshd-reachability-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic result carried forward

- EH_DIAGNOSTICS_RESULT=completed_read_only
- EH_MUTATION_RESULT=none
- CANDIDATE_SOURCE=one_time_local_shell_variable
- CANDIDATE_PRESENT=yes
- CONFIGURED_SSH_TARGET_HASH=7d65a629e9ce
- CONFIGURED_SSH_HOST_HASH=9960b990ae47
- CANDIDATE_TARGET_HASH=1544b40472dc
- CANDIDATE_HOST_HASH=1544b40472dc
- CANDIDATE_DIFFERS_FROM_CONFIGURED_TAILSCALE_ENDPOINT=yes
- ROUTE_TO_CANDIDATE_RC=0
- ROUTE_TO_CANDIDATE_PRESENT_OBSERVED=yes
- ROUTE_TO_CANDIDATE_HASH=5eb1ad5ce0b743da
- WIREGUARD_HOME_LINK_PRESENT=yes
- WIREGUARD_HOME_OPERSTATE=unknown
- WIREGUARD_HOME_WG_SHOW_AVAILABLE=no
- TAILSCALE_COMMAND_PRESENT=yes
- TAILSCALE_STATUS_SELF_RC=0
- CANDIDATE_TCP22_RESULT=connect_timeout
- CANDIDATE_BANNER_PREFIX=not_ssh_or_absent
- CANDIDATE_BANNER_VENDOR=none
- CANDIDATE_KEYSCAN_RC=1
- CANDIDATE_KEYSCAN_KEY_LINE_COUNT=0
- PROXMOX_LAN_SSHD_REACHABILITY_STATUS=local_route_exists_but_tcp22_timeout

## Interpretation

The EH diagnostic confirms the candidate differs from the configured Tailscale SSH endpoint, and the controller laptop has a local route to the candidate. However, TCP 22 still times out and ssh-keyscan returns no host keys.

EH_NARROWED_RESULT=local_route_exists_but_tcp22_timeout
DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no
DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no
DIRECT_PROXMOX_SSHD_CANDIDATE_DIFFERENT_FROM_TAILSCALE_ENDPOINT=yes
LOCAL_ROUTE_TO_CANDIDATE_PRESENT=yes
WIREGUARD_HOME_LINK_PRESENT_OBSERVED=yes
TCP22_TIMEOUT_CONFIRMED=yes
CANDIDATE_BANNER_PROBE_PERFORMED=yes
CANDIDATE_KEYSCAN_PROBE_PERFORMED=yes
CANDIDATE_REJECTED_AFTER_NETWORK_PROBE=yes
PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
SERVICE_ENV_MUTATION=not_performed
POWER_ENDPOINT_CALL=not_performed
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

The next likely investigation is host-side sshd/listener/firewall inspection on Proxmox, or VPN/LAN route correction. That should be planned separately and should remain guarded. Any Proxmox host command must be explicitly approved before execution.

## Safety state after diagnostics

- GIT_STATUS_AFTER=clean
- SERVICE_ACTIVE_AFTER=active
- SERVICE_ENABLED_AFTER=enabled
- SERVICE_FLAG_REMAINED_UNSET=verified
- SQLITE_QUICK_CHECK_AFTER=ok
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- JOB_SUMMARY_UNCHANGED=verified
- PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified

## Next phase

NEXT_PHASE_NAME=phase-14j-ei-proxmox-sshd-timeout-investigation-plan

The next phase should be docs/smoke-only planning for Proxmox host-side sshd listener, firewall, and LAN/VPN routing investigation. It should not call controller power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, mutate service environment, execute Proxmox remote commands, or activate scheduler/primary filtering.

## Boundaries preserved by EH

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- SERVICE_ENV_MUTATION=not_performed
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- HASH_ONLY_TARGET_COMPARISON=yes
- HASH_ONLY_HOSTKEY_OUTPUT=yes
- SANITIZED_LOCAL_ROUTE_INTERFACE_VPN_STATUS=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS_RESULT=completed_local_route_exists_but_tcp22_timeout

NEXT_SAFE_PHASE=proxmox_sshd_timeout_investigation_plan
