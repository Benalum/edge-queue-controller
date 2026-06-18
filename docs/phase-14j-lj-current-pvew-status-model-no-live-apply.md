# Phase 14J-LJ — Current PVEW status model, no live apply

Date: 2026-06-18

## Scope

Repo-only source/docs/smoke patch. No live service restart/reload and no runtime deployment.

## Change

Update the public `/system/status` presentation model away from legacy PVESO/CT101/laptop assumptions and toward the current PVEW deployment reality:

- PVEW is the always-on platform host.
- VM200 is the public website-edge VM.
- CT203 is the controller/API/queue authority.
- CT204 is backup-data-only, expected stopped, and not data authority.

## Rationale

After Phase 14J-KX/KZ/LB/LE-R2, the live platform is healthy on PVEW/VM200/CT203, but `/system/status` still reported `overall_state=degraded` because it hardcoded offline legacy items:

- `pveso`
- `ct-101`
- `ct101-laptop-queue-worker`
- laptop `edge-wrapper-ui.service`
- old power timers

Those legacy items no longer represent current public service health.

## Safety posture

This patch changes only repo source and validation artifacts. It does not deploy, reload, restart, probe host storage, mutate DB, mutate CT/VM config, or touch Cloudflare.

## Explicitly not changed

- No live CT203 deployment.
- No VM200 deployment.
- No service restart/reload.
- No DB mutation.
- No storage mutation.
- No CT/VM mutation.
- No Cloudflare/DNS/tunnel mutation.
