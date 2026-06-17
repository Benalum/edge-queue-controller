# Phase 14J-DX - SSH Handshake/Host-Key Timeout Read-Only Diagnostics

PHASE_14J_DX_SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_ssh_handshake_or_hostkey_timeout_read_only_diagnostics_result

This phase records the approved read-only SSH handshake/host-key timeout diagnostics.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run by this checkpoint phase. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment was printed. No raw SSH target or raw key path is recorded. Host-key output is hash-only.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=d6d09a0
- START_TAG=controller-phase-14j-dw-ssh-handshake-or-hostkey-timeout-diagnostics-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic results carried forward

- DX_DIAGNOSTICS_RESULT=completed_read_only
- DX_MUTATION_RESULT=none
- EDGE_PROXMOX_SSH_TARGET_PRESENT=yes
- EDGE_PROXMOX_SSH_TARGET_REDACTED_HASH=7d65a629e9ce
- EDGE_PROXMOX_SSH_USER_REDACTED_HASH=4813494d137e
- EDGE_PROXMOX_SSH_HOST_REDACTED_HASH=9960b990ae47
- EDGE_POWER_TARGET_MAP_PRESENT=yes
- EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes

## SSH banner and host-key diagnostics

- SSH_BANNER_RESULT=received
- SSH_BANNER_DURATION_MS=18
- SSH_BANNER_BYTES=19
- SSH_BANNER_PREFIX=SSH-2.0
- SSH_BANNER_HASH=e687598eb9c872c4
- SSH_BANNER_VENDOR_SANITIZED=Tailscale
- SSH_KEYSCAN_RC=0
- SSH_KEYSCAN_STDOUT_SIZE=837
- SSH_KEYSCAN_STDERR_SIZE=185
- SSH_KEYSCAN_KEY_LINE_COUNT=3
- SSH_KEYSCAN_KEY_TYPES=ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa
- SSH_KEYSCAN_HOSTKEY_HASHES=sha256:87ab4e6a51e85cae,sha256:367e92ade6ad5d48,sha256:4afc7b099071815d

## SSH command diagnostics

- SSH_KEYSCAN_STRICT_TRUE_RC=255
- SSH_KEYSCAN_STRICT_TRUE_STDOUT_SIZE=0
- SSH_KEYSCAN_STRICT_TRUE_STDERR_SIZE=6457
- SSH_KEYSCAN_STRICT_CONNECTION_ESTABLISHED=yes
- SSH_KEYSCAN_STRICT_REMOTE_PROTOCOL_SEEN=yes
- SSH_KEYSCAN_STRICT_KEXINIT_SEEN=yes
- SSH_KEYSCAN_STRICT_SERVER_HOSTKEY_SEEN=yes
- SSH_KEYSCAN_STRICT_HOSTKEY_VERIFICATION_FAILED=no
- SSH_KEYSCAN_STRICT_AUTH_CONTINUE_SEEN=no
- SSH_KEYSCAN_STRICT_OFFERING_PUBLICKEY=no
- SSH_KEYSCAN_STRICT_AUTHENTICATED=no
- SSH_KEYSCAN_STRICT_REMOTE_COMMAND_EXECUTED=no
- SSH_KEYSCAN_STRICT_TIMEOUT_SEEN=yes
- SSH_KEYSCAN_STRICT_CLASSIFICATION=post_hostkey_pre_auth_timeout

- SSH_ACCEPTNEW_TRUE_RC=255
- SSH_ACCEPTNEW_TRUE_STDOUT_SIZE=0
- SSH_ACCEPTNEW_TRUE_STDERR_SIZE=6459
- SSH_ACCEPTNEW_CONNECTION_ESTABLISHED=yes
- SSH_ACCEPTNEW_REMOTE_PROTOCOL_SEEN=yes
- SSH_ACCEPTNEW_KEXINIT_SEEN=yes
- SSH_ACCEPTNEW_SERVER_HOSTKEY_SEEN=yes
- SSH_ACCEPTNEW_HOSTKEY_VERIFICATION_FAILED=no
- SSH_ACCEPTNEW_AUTH_CONTINUE_SEEN=no
- SSH_ACCEPTNEW_OFFERING_PUBLICKEY=no
- SSH_ACCEPTNEW_AUTHENTICATED=no
- SSH_ACCEPTNEW_REMOTE_COMMAND_EXECUTED=no
- SSH_ACCEPTNEW_TIMEOUT_SEEN=yes
- SSH_ACCEPTNEW_CLASSIFICATION=post_hostkey_pre_auth_timeout

- SSH_PUBKEY_ONLY_IDENTITIESONLY_TRUE_RC=255
- SSH_PUBKEY_ONLY_IDENTITIESONLY_TRUE_STDOUT_SIZE=0
- SSH_PUBKEY_ONLY_IDENTITIESONLY_TRUE_STDERR_SIZE=6457
- SSH_PUBKEY_ONLY_IDENTITIESONLY_CONNECTION_ESTABLISHED=yes
- SSH_PUBKEY_ONLY_IDENTITIESONLY_REMOTE_PROTOCOL_SEEN=yes
- SSH_PUBKEY_ONLY_IDENTITIESONLY_KEXINIT_SEEN=yes
- SSH_PUBKEY_ONLY_IDENTITIESONLY_SERVER_HOSTKEY_SEEN=yes
- SSH_PUBKEY_ONLY_IDENTITIESONLY_HOSTKEY_VERIFICATION_FAILED=no
- SSH_PUBKEY_ONLY_IDENTITIESONLY_AUTH_CONTINUE_SEEN=no
- SSH_PUBKEY_ONLY_IDENTITIESONLY_OFFERING_PUBLICKEY=no
- SSH_PUBKEY_ONLY_IDENTITIESONLY_AUTHENTICATED=no
- SSH_PUBKEY_ONLY_IDENTITIESONLY_REMOTE_COMMAND_EXECUTED=no
- SSH_PUBKEY_ONLY_IDENTITIESONLY_TIMEOUT_SEEN=yes
- SSH_PUBKEY_ONLY_IDENTITIESONLY_CLASSIFICATION=post_hostkey_pre_auth_timeout

## Effective SSH config observations

- SSH_G_RC=0
- SSH_G_USER_PRESENT=yes
- SSH_G_HOSTNAME_PRESENT=yes
- SSH_G_IDENTITYFILE_COUNT=7
- SSH_G_IDENTITYFILE_EXISTING_COUNT=1
- SSH_G_IDENTITIESONLY=no
- SSH_G_STRICTHOSTKEYCHECKING=ask
- SSH_G_BATCHMODE=yes
- SSH_G_PROXYJUMP_PRESENT=no
- SSH_G_PROXYCOMMAND_PRESENT=no
- SSH_G_PREFERREDAUTHENTICATIONS_PRESENT=unknown

## Interpretation

TCP port 22 is reachable, an SSH-2.0 banner is received, ssh-keyscan returns host keys, and host-key verification is not failing. However, strict host-key, accept-new, and publickey-only identities-only SSH attempts all fail with rc 255 after the server host key is seen and before authentication begins or any remote command executes.

DX_NARROWED_ROOT_CAUSE_AREA=tailscale_ssh_or_pre_auth_policy_timeout_after_hostkey
SSH_BANNER_AND_KEYSCAN_SUCCEED=yes
SSH_HOSTKEY_VERIFICATION_FAILURE=no
SSH_POST_HOSTKEY_PRE_AUTH_TIMEOUT=yes
SSH_REMOTE_COMMAND_EXECUTION_REACHED=no
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

The sanitized keyscan banner identifies the endpoint as Tailscale. The next work should determine whether the configured target is intentionally using Tailscale SSH, whether Tailscale SSH policy/ACL approval is blocking noninteractive BatchMode SSH, or whether the controller should instead target the Proxmox host SSH daemon through a different address/path.

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

NEXT_PHASE_NAME=phase-14j-dy-tailscale-ssh-vs-proxmox-sshd-target-plan

The next phase should be docs/smoke-only planning for whether the controller should use Tailscale SSH or direct Proxmox sshd for noninteractive power inventory/start planning. It should not call controller power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, or activate scheduler/primary filtering.

## Boundaries preserved by DX

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL_IN_CHECKPOINT=not_performed
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

SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed

NEXT_SAFE_PHASE=tailscale_ssh_vs_proxmox_sshd_target_plan
