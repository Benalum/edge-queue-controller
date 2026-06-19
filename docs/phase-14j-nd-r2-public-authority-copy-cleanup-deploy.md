# Phase 14J-ND-R2 — Public Authority Copy Cleanup Deploy

Date: 2026-06-18

Approved phrase:

`APPROVE_PHASE_14J_ND_R2_PUBLIC_AUTHORITY_COPY_CLEANUP_DEPLOY_NO_SERVICE_RESTART`

## Scope

Patched stale public static UI copy in `frontend/wrapper-ui/app.js` from `laptop controller-owned` to `CT203/controller-owned`.

Deployed updated app asset to VM200 path:

`/var/www/apc-wrapper-local/app.js`

## Boundaries

- No PVESO wake/start.
- No worker activation.
- No model endpoint call.
- No scheduler dispatch.
- No private storage unlock/mount.
- No CT204 start or data authority change.
- No Cloudflare/DNS/tunnel mutation.
- No DB restore/import/migration.
- No service restart/reload/enable/start/stop.

## Evidence

- Corrected app hash: `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`
- Public app path: `/app.js?v=2026061814jlbr2`
- Direct terminal used because PPB timed out repeatedly during rescue.
