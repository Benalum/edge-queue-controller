# Phase 14J-KB — CT203 boot persistence and rollback plan, no apply

Date: 2026-06-18

## Scope

This is a no-apply planning phase for making CT203 persistent across PVEW reboot.

This phase performs no live infrastructure mutation.

## Current state

- PVEW is the target platform host.
- VM200 is public edge/static/nginx/cloudflared.
- CT203 is the private controller/API/queue candidate.
- CT203 controller service is active.
- CT203 controller service is intentionally disabled at boot.
- CT203 container onboot remains disabled.
- CT204 remains stopped.
- VM200 bridges public API/controller paths to CT203.
- Public human SPA routes return the wrapper.
- Public `/public/status` and `/system/local-health` reach CT203.

## Proposed apply phase, not executed here

A later explicit approval phase may perform only:

1. Confirm current healthy state.
2. Confirm CT203 service is active and DB integrity is OK.
3. Enable the CT203 controller systemd service.
4. Set CT203 `onboot: 1`.
5. Verify CT203 service enabled state.
6. Verify CT203 config onboot state.
7. Verify public routes still work.

## Rollback plan

If boot persistence causes problems, rollback should:

1. Disable CT203 controller systemd service.
2. Set CT203 `onboot: 0`.
3. Leave VM200 static wrapper and nginx bridge untouched unless separately required.
4. Confirm CT203 can still be manually started.
5. Confirm public wrapper routes remain available.
6. Do not change DB authority during rollback.

## Safety boundaries

The apply phase must not include:

- Cloudflare, DNS, or tunnel mutation
- VM200 nginx mutation
- static wrapper replacement
- DB restore/import/authority change
- CT204 start
- PVESO wake
- storage/crypttab/fstab mutation
- PVEW quorum normalization
- GitHub branch/repository deletion

## Required approval for apply

Use a separate explicit approval before any real mutation:

APPROVE_PHASE_14J_KC_ENABLE_CT203_BOOT_PERSISTENCE_NO_DB_NO_CLOUDFLARE_NO_VM200_MUTATION
