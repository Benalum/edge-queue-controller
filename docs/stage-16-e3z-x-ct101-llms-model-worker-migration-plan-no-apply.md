# Stage 16 E3Z-X: CT101 llms model-worker migration plan (no apply)

## Scope markers

E3Z_X_NO_APPLY_PLAN=1
E3Z_X_NO_LIVE_INFRA_MUTATION=1
E3Z_X_NO_CT_START_STOP_RESTART=1
E3Z_X_NO_SERVICE_OR_TIMER_ACTIVATION=1
E3Z_X_NO_SYSTEMCTL_DAEMON_RELOAD=1
E3Z_X_NO_DB_WRITE_OR_JOB_MUTATION=1
E3Z_X_NO_MODEL_OR_OLLAMA_ENDPOINT_CALL=1
E3Z_X_CT101_LLMS_REPLICABLE_MODEL_WORKER_TARGET=1
E3Z_X_PVESO_HOST_OLLAMA_LEGACY_TEMPORARY_PATH=1
E3Z_X_THIN_COMPANION_VERTICAL_SLICE_AFTER_CT101_PROOF=1

This is a repository-only planning checkpoint. It does not start CT101, does not start Ollama, does not change systemd, does not run systemctl daemon-reload, does not start any timer, does not mutate the database, and does not call any model endpoint.

## Architecture decision

CT101 llms becomes the replicable model-worker unit.

The desired production shape is:

- CT203 remains the controller, scheduler, queue, and database authority.
- PVESO remains a Proxmox model-worker host.
- CT101 llms becomes the model runtime container on PVESO.
- Future model workers should be cloneable across Proxmox hosts by repeating the CT101 worker shape.
- PVESO host-level Ollama is treated as a temporary legacy proof path, not the final worker architecture.

## What the archaeology proved

Stage 16 E3Z-V and E3Z-W showed that prior successful scheduler/model proofs used PVESO host-level Ollama through SSH and localhost 127.0.0.1:11434 on the PVESO host. The old dispatch scripts intentionally checked that CT101 was stopped and onboot disabled before using host-level Ollama.

That means the earlier proof validated the queue-to-scheduler-to-helper pattern, but not the final CT101 llms worker placement.

## Required safety gates before any CT101 apply step

Before starting or changing CT101, a separate read-only guard must prove:

1. CT203 controller and public status are healthy.
2. Scheduler service is inactive/static.
3. Scheduler timer is inactive/disabled.
4. There are no real scheduler processes.
5. Jobs 35 and 36 remain queued with attempts 0 and result rows 0, or a fresh exact allowlist is chosen.
6. Jobs 29, 30, 31, 32, 33, and 34 remain hard no-rerun jobs.
7. PVESO LAN SSH target is stable and non-interactive from CT203.
8. CT101 config is recorded before any mutation.
9. CT101 onboot remains disabled unless a later explicit worker-autostart phase approves otherwise.
10. No broad scheduler dispatch or persistent worker activation is enabled.

## No-apply migration sequence

The next phases should remain narrow:

1. CT101 stopped-state readiness guard, read-only.
2. CT101 start-only approval boundary.
3. CT101 boot/readiness check, read-only after start.
4. CT101 Ollama inventory/readiness check, read-only where possible.
5. If Ollama is absent or stopped, create a no-apply install/service plan first.
6. If CT101 model runtime becomes ready, create an exact-job scheduler/helper path that targets CT101 only.
7. Complete one bounded model proof through CT101 llms.
8. Only after CT101 worker path is proven, build the thin companion vertical slice.
9. After the vertical slice is proven, use Codex/refactor work to consolidate PPB guards and scheduler artifacts.

## Explicit approval boundaries

The following require separate explicit approval:

- starting CT101;
- stopping or restarting CT101;
- enabling CT101 onboot;
- installing packages or changing CT101 files;
- starting, stopping, enabling, or reconfiguring Ollama;
- changing PVESO or CT101 SSH authorization;
- changing scheduler systemd drop-ins;
- running systemctl daemon-reload;
- starting timers or services;
- any DB write, job claim, job retry, status update, result insert, or model call.

## Success definition for this no-apply checkpoint

This checkpoint is complete when the repository contains a committed plan and smoke test that encode the architecture pivot from PVESO host-level Ollama to CT101 llms as the replicable model-worker unit.
