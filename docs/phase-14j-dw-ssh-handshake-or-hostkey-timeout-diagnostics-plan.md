# Phase 14J-DW - SSH Handshake or Host-Key Timeout Diagnostics Plan

PHASE_14J_DW_SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_DIAGNOSTICS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_ssh_handshake_or_hostkey_timeout_diagnostics_plan

This phase plans the next diagnostics after Phase 14J-DV narrowed the Proxmox inventory failure to SSH rc 255 after TCP port 22 is reachable.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=8d0eadc
- START_TAG=controller-phase-14j-dv-ssh-rc-255-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DV finding carried forward

- SSH_RC_255_READ_ONLY_DIAGNOSTICS_RESULT=completed
- DV_NARROWED_ROOT_CAUSE_AREA=ssh_handshake_or_host_key_or_auth_timeout_after_tcp_connect
- TCP_22_RESULT=open
- TAILSCALE_PEER_ONLINE=true
- SSH_VERBOSE_TRUE_RC=255
- SSH_VERBOSE_ERROR_CLASSIFICATIONS=timeout,host_key
- SSH_ACCEPTNEW_TRUE_RC=255
- SSH_ACCEPTNEW_ERROR_CLASSIFICATIONS=timeout,host_key
- SSH_G_IDENTITYFILE_EXISTING_COUNT=1
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Diagnosis objective

SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_DIAGNOSTICS_PLAN=ready_for_explicit_read_only_diagnostics

The next diagnostic phase should classify why SSH reaches TCP port 22 but fails before a remote command can execute.

Possible causes to distinguish:

1. SSH server accepts TCP but stalls during banner, KEX, host-key exchange, or auth.
2. Host-key verification or known-hosts handling is causing the rc 255 path.
3. SSH authentication/key mismatch is causing a silent or slow failure.
4. The one existing identity file is not the intended identity for the Proxmox target.
5. The Proxmox SSH daemon is overloaded, rate-limiting, or configured with delayed auth.
6. The target resolves to an address with open port 22 that is not the intended Proxmox host.
7. Local SSH config is choosing unexpected options or identities.

## Allowed diagnostics for next phase

The next phase may perform read-only diagnostics with short timeouts and sanitized output only:

- CHECK_SSH_BANNER_ONLY_SHORT_TIMEOUT=yes
- CHECK_SSH_KEYSCAN_HASH_ONLY=yes
- CHECK_SSH_ACCEPTNEW_WITH_EMPTY_KNOWN_HOSTS_SANITIZED=yes
- CHECK_SSH_PREFERRED_AUTHENTICATIONS_PUBLICKEY_ONLY=yes
- CHECK_SSH_IDENTITIES_ONLY_TRUE=yes
- CHECK_SSH_CONFIG_EFFECTIVE_REDACTED=yes
- CHECK_SSH_HOSTKEY_CLASSIFICATION=yes
- CHECK_SSH_AUTH_TIMEOUT_CLASSIFICATION=yes
- CHECK_TCP_22_RECHECK_SHORT_TIMEOUT=yes
- CHECK_TAILSCALE_PEER_ONLINE_REDACTED=yes

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
- REQUIRE_SANITIZED_OUTPUT=yes
- REQUIRE_NO_SECRET_PRINTING=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_HASH_ONLY_HOSTKEY_OUTPUT=yes

## Decision

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_DIAGNOSIS_REQUIRED=yes

The guarded worker start endpoint remains blocked until SSH can run a harmless read-only command successfully or the failure is classified and fixed in a later approved phase.

## Next phase

NEXT_PHASE_NAME=phase-14j-dx-ssh-handshake-or-hostkey-timeout-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-DX SSH handshake/host-key timeout read-only diagnostics with sanitized output and short timeouts, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DW

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

SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_DIAGNOSTICS_PLAN_RESULT=ready_for_explicit_read_only_diagnostics

NEXT_SAFE_PHASE=ssh_handshake_or_hostkey_timeout_read_only_diagnostics_requires_approval
