# Stage 16-E1A — Existing PVESO Auto-Power Endpoint Rediscovery, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-E0 / HEAD 51c1689

## Scope

Stage 16-E1A rediscovers existing PVESO, llms, wake, boot, shutdown, and auto-power endpoint/code paths.

This is a no-apply endpoint inventory phase.

It does not wake PVESO.

It does not mutate PVESO.

It does not mutate PVEW.

It does not deploy backend code.

It does not deploy frontend code.

It does not write the database.

It does not start, stop, restart, reload, enable, or disable services.

It does not start or stop CTs or VMs.

It does not activate workers.

It does not activate schedulers.

It does not call Ollama endpoints.

It does not call model endpoints.

It does not run ollama list, ollama pull, ollama run, or ollama show.

It does not call /tick/ollama-direct.

It does not invoke any power, wake, boot, or shutdown endpoint.

## Reason

The project previously had PVESO/llms worker and power-control work.

Before designing anything new, Stage 16-E1A rediscovers existing code and deployed endpoint paths.

## Target architecture reminder

PVESO is intentionally offline by default.

PVESO is the primary on-demand model worker host.

PVEW remains the always-on platform host.

CT203 remains controller/API/queue/decision authority.

VM200 remains public/static edge.

CT204 remains stopped backup-data-only.

PVEW replica/helper worker comes later.

## Required interpretation

If existing PVESO power endpoints are present, reuse them rather than inventing a new control surface.

If endpoints exist but are unsafe or incomplete, Stage 16-E1B should design a hardening wrapper.

If endpoints are absent, Stage 16-E1B should design the new auto-power controller.

## Next phase

Stage 16-E1B should convert the rediscovered endpoint inventory into an exact no-apply auto-power controller design.

It must define:

- which existing endpoints are reusable;
- which endpoints are prohibited until approval;
- exact wake path;
- exact shutdown path;
- exact health-check path;
- exact manual override path;
- exact audit evidence;
- exact rollback path;
- exact approval boundary for PVESO wake readiness.

## Approval boundary remains

PVESO wake readiness must still require:

APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB

Worker bridge prep must still require:

APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION

The one real queued model test must still require:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST
