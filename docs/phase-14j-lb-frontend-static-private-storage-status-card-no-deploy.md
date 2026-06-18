# Phase 14J-LB — Frontend static private storage status card, no deploy

Date: 2026-06-18

## Scope

Repo-only frontend/docs/smoke patch. No VM200 deployment and no live service reload.

## Change

Add frontend rendering support for the already-live `/system/status.private_storage_status` block.

The UI now maps the API block into the existing Storage Nodes infrastructure card:

- `policy`
- `mount_state`
- `mountpoint`
- CT204 expected state
- CT204 data authority

## Rationale

Phase 14J-KX/KZ made the backend expose a public-safe static encrypted storage policy block. This patch makes the wrapper UI ready to display that state without pretending CT203 can inspect the live PVEW host mount.

## Explicitly not changed

- No VM200 deployment.
- No live service restart/reload.
- No storage mutation.
- No DB mutation.
- No CT/VM mutation.
- No Cloudflare/DNS/tunnel mutation.
