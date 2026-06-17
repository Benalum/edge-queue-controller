# Phase 14J-DZ - Tailscale SSH vs Proxmox sshd Target Read-Only Diagnostics

PHASE_14J_DZ_TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_vs_proxmox_sshd_target_read_only_diagnostics_result

This phase records the approved read-only diagnostics comparing the configured controller SSH target path against a direct Proxmox sshd candidate path.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run by this checkpoint phase. No Proxmox remote command is executed. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment was printed. No raw SSH target or raw key path is recorded. Host-key output is hash-only.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=a95f31c
- START_TAG=controller-phase-14j-dy-tailscale-ssh-vs-proxmox-sshd-target-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic results carried forward

- DZ_DIAGNOSTICS_RESULT=completed_read_only
- DZ_MUTATION_RESULT=none
- EDGE_PROXMOX_SSH_TARGET_PRESENT=yes
- EDGE_PROXMOX_SSH_TARGET_REDACTED_HASH=7d65a629e9ce
- EDGE_PROXMOX_SSH_HOST_REDACTED_HASH=9960b990ae47
- EDGE_PROXMOX_HOST_PRESENT=yes
- EDGE_PROXMOX_HOST_REDACTED_HASH=9960b990ae47
- EDGE_POWER_TARGET_MAP_PRESENT=yes
- EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes

## Tailscale target match diagnostics

- TAILSCALE_STATUS_RC=0
- TAILSCALE_BACKEND_STATE=Running
- TAILSCALE_PEER_COUNT=3
- CONFIGURED_SSH_HOST_HASH=9960b990ae47
- CONFIGURED_SSH_HOST_TAILSCALE_PEER_MATCH=yes
- CONFIGURED_SSH_HOST_TAILSCALE_PEER_ONLINE=true
- EDGE_PROXMOX_HOST_HASH=9960b990ae47
- EDGE_PROXMOX_HOST_TAILSCALE_PEER_MATCH=yes
- EDGE_PROXMOX_HOST_TAILSCALE_PEER_ONLINE=true
- CONFIGURED_SSH_HOST_EQUALS_EDGE_PROXMOX_HOST=yes

## Configured SSH host banner/keyscan diagnostics

- CONFIGURED_SSH_HOST_PRESENT=yes
- CONFIGURED_SSH_HOST_HOST_HASH=9960b990ae47
- CONFIGURED_SSH_HOST_TCP22_RESULT=received
- CONFIGURED_SSH_HOST_TCP22_DURATION_MS=22
- CONFIGURED_SSH_HOST_BANNER_BYTES=19
- CONFIGURED_SSH_HOST_BANNER_PREFIX=SSH-2.0
- CONFIGURED_SSH_HOST_BANNER_VENDOR=Tailscale
- CONFIGURED_SSH_HOST_BANNER_HASH=e687598eb9c872c4
- CONFIGURED_SSH_HOST_KEYSCAN_RC=0
- CONFIGURED_SSH_HOST_KEYSCAN_STDOUT_SIZE=837
- CONFIGURED_SSH_HOST_KEYSCAN_STDERR_SIZE=185
- CONFIGURED_SSH_HOST_KEYSCAN_KEY_LINE_COUNT=3
- CONFIGURED_SSH_HOST_KEYSCAN_KEY_TYPES=ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa
- CONFIGURED_SSH_HOST_KEYSCAN_HOSTKEY_HASHES=sha256:367e92ade6ad5d48,sha256:87ab4e6a51e85cae,sha256:4afc7b099071815d

## Direct Proxmox sshd candidate diagnostics

- EDGE_PROXMOX_HOST_PRESENT=yes_same_as_configured_ssh_host
- EDGE_PROXMOX_HOST_HOST_HASH=9960b990ae47
- EDGE_PROXMOX_HOST_TCP22_RESULT=skipped_same_or_missing
- EDGE_PROXMOX_HOST_BANNER_VENDOR=unknown
- EDGE_PROXMOX_HOST_KEYSCAN_RC=skipped_same_or_missing
- EDGE_PROXMOX_HOST_KEYSCAN_KEY_LINE_COUNT=0
- EDGE_PROXMOX_HOST_KEYSCAN_KEY_TYPES=none
- EDGE_PROXMOX_HOST_KEYSCAN_HOSTKEY_HASHES=none

## Target decision summary

- TARGET_DECISION_INPUTS_RECORDED=yes
- TARGET_DECISION_REQUIRES_CHECKPOINT_INTERPRETATION=yes
- TARGET_DECISION_DEFAULT_RECOMMENDATION=prefer_direct_proxmox_sshd_for_noninteractive_controller_automation_if_available
- TARGET_DECISION_TAILSCALE_SSH_ENDPOINT_BATCHMODE_STATUS=not_suitable_based_on_dx_pre_auth_timeout
- TARGET_DECISION_NEXT_ACTION=checkpoint_results_and_plan_target_fix_or_direct_sshd_candidate

## Interpretation

The configured controller SSH target host and EDGE_PROXMOX_HOST resolve to the same redacted target hash. That target is a Tailscale peer and is online, but its port 22 banner identifies the endpoint as Tailscale. No separate direct Proxmox sshd candidate is currently present in the controller environment.

DZ_NARROWED_ROOT_CAUSE_AREA=configured_target_is_tailscale_ssh_endpoint_no_direct_proxmox_sshd_candidate_present
CONFIGURED_TARGET_VENDOR=Tailscale
EDGE_PROXMOX_HOST_SAME_AS_CONFIGURED_SSH_HOST=yes
DIRECT_PROXMOX_SSHD_CANDIDATE_PRESENT=no
TAILSCALE_SSH_BATCHMODE_NOT_SUITABLE_FOR_CONTROLLER_AUTOMATION=yes
PREFERRED_TARGET_FOR_NONINTERACTIVE_CONTROLLER_AUTOMATION=direct_proxmox_sshd_if_available
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

The next work should plan a safe way to identify or configure a direct Proxmox sshd target for noninteractive controller automation, then verify that candidate with read-only banner/keyscan/harmless command diagnostics before any power endpoint or worker-start path is retried.

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

NEXT_PHASE_NAME=phase-14j-ea-direct-proxmox-sshd-target-candidate-plan

The next phase should be docs/smoke-only planning for a direct Proxmox sshd target candidate. It should not call controller power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, or activate scheduler/primary filtering.

## Boundaries preserved by DZ

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL_IN_CHECKPOINT=not_performed
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- HASH_ONLY_HOSTKEY_OUTPUT=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_READ_ONLY_DIAGNOSTICS_RESULT=completed

NEXT_SAFE_PHASE=direct_proxmox_sshd_target_candidate_plan
