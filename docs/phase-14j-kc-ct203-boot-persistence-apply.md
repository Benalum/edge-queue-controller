# Phase 14J-KC — CT203 boot persistence apply

Date: 2026-06-18

## Scope

This checkpoint records the approved CT203 boot-persistence apply.

## Approval

APPROVE_PHASE_14J_KC_ENABLE_CT203_BOOT_PERSISTENCE_NO_DB_NO_CLOUDFLARE_NO_VM200_MUTATION

## Applied mutation

Only these runtime changes were applied:

- Enabled `edge-queue-controller.service` inside CT203.
- Set CT203 `onboot: 1`.

## Explicitly not changed

- No DB mutation.
- No DB authority change.
- No Cloudflare, DNS, or tunnel mutation.
- No VM200 nginx/static mutation.
- No CT204 start.
- No PVESO wake.

## Verified result

- CT203 controller service is active.
- CT203 controller service is enabled.
- CT203 container has `onboot: 1`.
- CT203 DB integrity check returned `ok`.
- CT204 remained stopped.
- Public `/` returned 200.
- Public `/system` returned 200.
- Public `/public/status` returned 200.
- Public `/system/local-health` returned 200.

## Current posture

CT203 should now return automatically after PVEW reboot. CT203 is the controller container. CT204 remains the separate data/backups container and is not live data authority.
