# Phase 14J-EE - Direct Proxmox sshd Candidate Discovery Plan

PHASE_14J_EE_DIRECT_PROXMOX_SSHD_CANDIDATE_DISCOVERY_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_candidate_discovery_plan

This phase plans a local-only way to discover a valid direct Proxmox OpenSSH daemon candidate without exposing raw hosts, IPs, key paths, or secrets in chat.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=c79d699
- START_TAG=controller-phase-14j-ed-direct-proxmox-sshd-target-candidate-read-only-diagnostics-retry-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## ED finding carried forward

- DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RETRY_RESULT=completed_invalid_same_candidate
- ED_NARROWED_RESULT=retry_candidate_is_same_configured_tailscale_ssh_endpoint
- DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no
- DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no
- CANDIDATE_REJECTED_BEFORE_NETWORK_PROBE=yes
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Discovery objective

DIRECT_PROXMOX_SSHD_CANDIDATE_DISCOVERY_PLAN=ready

The current configured Proxmox SSH target path resolves to Tailscale SSH, and the EB/ED candidate attempts reused the same redacted host hash. A valid candidate must reach native Proxmox OpenSSH daemon and must not match the configured Tailscale SSH endpoint hash.

## Local discovery checklist

Use local-only inspection. Do not paste raw values into chat.

1. Check Proxmox console or router DHCP/reservation for the Proxmox management LAN IP.
2. Check local network notes for the Proxmox host management IP or DNS name.
3. Check WireGuard/VPN management subnet notes if Proxmox has a direct VPN address.
4. Avoid the existing Tailscale SSH endpoint that returns the Tailscale SSH banner.
5. Set only a local shell variable for the next test.
6. Paste only sanitized PPB output back to chat.

## Candidate acceptance rules

- DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes
- SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes
- CANDIDATE_MUST_DIFFER_FROM_CONFIGURED_TAILSCALE_ENDPOINT_HASH=yes
- CANDIDATE_EXPECTED_BANNER_VENDOR=OpenSSH_or_other_non_Tailscale_sshd
- CANDIDATE_TAILSCALE_BANNER_IS_INVALID=yes
- CANDIDATE_FIRST_CHECK_ALLOWED_TCP_22_BANNER_ONLY=yes
- CANDIDATE_FIRST_CHECK_ALLOWED_KEYSCAN_HASH_ONLY=yes
- CANDIDATE_FIRST_CHECK_PROXMOX_REMOTE_COMMAND_EXECUTION=no
- CANDIDATE_FIRST_CHECK_SERVICE_ENV_MUTATION=no
- CANDIDATE_FIRST_CHECK_POWER_ENDPOINT_CALL=no

## Suggested local variable for next retry

Use a different target locally:

export APC_EF_DIRECT_PROXMOX_SSHD_CANDIDATE="DIRECT_PROXMOX_NATIVE_SSHD_HOST_OR_IP"

Do not paste the raw value into chat.

## Next phase

NEXT_PHASE_NAME=phase-14j-ef-direct-proxmox-sshd-candidate-read-only-diagnostics-second-retry

Required approval text for the next phase:

I approve Phase 14J-EF direct Proxmox sshd candidate read-only diagnostics second retry with sanitized output and short timeouts, using only a one-time local shell variable I provide, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no Proxmox remote command execution, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EE

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
- PROXMOX_SSH_CALL=not_performed
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- HASH_ONLY_TARGET_COMPARISON=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

DIRECT_PROXMOX_SSHD_CANDIDATE_DISCOVERY_PLAN_RESULT=ready_for_local_candidate_discovery

NEXT_SAFE_PHASE=direct_proxmox_sshd_candidate_read_only_diagnostics_second_retry_requires_approval
