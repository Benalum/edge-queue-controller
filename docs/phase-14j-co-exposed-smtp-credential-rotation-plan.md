# Phase 14J-CO - Exposed SMTP Credential Rotation Plan

PHASE_14J_CO_EXPOSED_SMTP_CREDENTIAL_ROTATION_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_security_rotation_plan

This phase records the safe plan for rotating the previously exposed SMTP credential.

No secret is printed. No secret is rotated in this phase. No service is restarted or reloaded in this phase.

## Starting checkpoint

- START_HEAD=cc191c1
- START_TAG=controller-phase-14j-cn-post-patch-gate-b0-result-checkpoint-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- lane_enabled_worker_count=0

## Security finding

SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential

A prior diagnostic printed a systemd SMTP password in terminal/chat/log output. Treat that SMTP credential as compromised.

## Rotation rules

- DO_NOT_PRINT_SECRETS=yes
- DO_NOT_PASTE_SECRET_IN_CHAT=yes
- DO_NOT_PASTE_SECRET_IN_PPB_BLOCK=yes
- DO_NOT_RUN_FULL_SYSTEMCTL_CAT=yes
- DO_NOT_PRINT_FULL_SYSTEMD_ENVIRONMENT=yes
- ROTATION_MUST_BE_INTERACTIVE_OR_LOCAL_ONLY=yes
- ROTATION_SCRIPT_MUST_USE_SILENT_INPUT=yes
- ROTATION_SCRIPT_MUST_NOT_ECHO_SECRET=yes
- ROTATION_SCRIPT_MUST_NOT_TEE_SECRET_TO_STDOUT=yes

## Rotation plan

The next security phase should:

1. Generate or obtain a new SMTP password/app password from the mail provider.
2. Run a local interactive terminal script, not a PPB code block containing the secret.
3. Prompt for the new secret using silent input.
4. Write only the systemd drop-in file needed for SMTP credentials.
5. Run daemon-reload and restart only `edge-queue-controller.service`.
6. Verify service active.
7. Verify email-related configuration without printing secret values.
8. Verify `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains unset.
9. Verify DB quick_check remains ok.
10. Record a post-rotation checkpoint.

## Boundaries preserved in CO

- SECRET_ROTATION=not_performed
- SOURCE_MUTATION=not_performed
- DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- NO_SECRETS_PRINTED=yes

## Result

NEXT_SAFE_PHASE=interactive_rotate_exposed_smtp_credential_or_gate_b1_worker_availability_metadata_plan
