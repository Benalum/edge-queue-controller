# Phase 14J-EC - Direct Proxmox sshd Candidate Selection Guidance

PHASE_14J_EC_DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE

## Scope

MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_candidate_selection_guidance

This phase records guidance for selecting a different direct Proxmox OpenSSH daemon target candidate without exposing raw hosts, IPs, key paths, or secrets in chat.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=fd0beec
- START_TAG=controller-phase-14j-eb-direct-proxmox-sshd-target-candidate-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## EB finding carried forward

- DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RESULT=completed_invalid_same_candidate
- EB_NARROWED_RESULT=provided_candidate_is_same_configured_tailscale_ssh_endpoint
- DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no
- DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no
- CANDIDATE_REJECTED_BEFORE_NETWORK_PROBE=yes
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Candidate selection guidance

DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE=ready

The previous candidate was the same host as the configured Tailscale SSH endpoint. A valid next candidate must be a different path to the Proxmox host's native OpenSSH daemon.

Acceptable candidate examples to test locally, without pasting raw values into chat:

1. A LAN management IP for the Proxmox host.
2. A VPN/WireGuard management IP for the Proxmox host.
3. A direct DNS name that resolves to Proxmox sshd and not the Tailscale SSH endpoint.
4. A Tailscale path only if it reaches native Proxmox sshd instead of Tailscale SSH; current evidence says the configured Tailscale target reaches Tailscale SSH and is not suitable.

## Local-only candidate rules

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

## Recommended local preparation

Before rerunning candidate diagnostics, choose a different target locally and set:

```bash
export APC_EB_DIRECT_PROXMOX_SSHD_CANDIDATE="DIRECT_PROXMOX_SSHD_HOST_OR_IP"
```

The candidate must not be the current Tailscale SSH hostname/IP that produced the Tailscale banner. Do not paste the raw value into chat. Paste only the sanitized PPB output.

## Next diagnostic path

The next diagnostic phase should reuse the EB candidate read-only diagnostic with a different local candidate, or use a new ED phase if we want a separate checkpoint name.

Recommended next phase name:

NEXT_PHASE_NAME=phase-14j-ed-direct-proxmox-sshd-target-candidate-read-only-diagnostics-retry

Required approval text for the next phase:

I approve Phase 14J-ED direct Proxmox sshd target candidate read-only diagnostics retry with sanitized output and short timeouts, using only a one-time local shell variable I provide, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no Proxmox remote command execution, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EC

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

DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE_RESULT=ready_for_local_candidate_retry

NEXT_SAFE_PHASE=direct_proxmox_sshd_target_candidate_read_only_diagnostics_retry_requires_approval
