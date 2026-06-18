# Phase 14J-LY — UI Legacy Copy Source Patch, No Deploy

Updated: 2026-06-18

## Purpose

This phase records a repo-only source patch that removes active public wrapper app legacy references found during Phase 14J-LW and planned in Phase 14J-LX.

This phase does not deploy the frontend to VM200, write to VM200, run qemu guest-agent operations, deploy controller source, restart services, mutate DBs, mutate storage, start CT204, wake PVESO, connect over SSH, edit SSH config, or change Cloudflare/DNS/tunnels.

## Prior checkpoint

- Phase: 14J-LX — UI Legacy Copy Cleanup Plan, No Deploy.
- Commit: `843c93e`.
- Tag: `controller-phase-14j-lx-ui-legacy-copy-cleanup-plan-no-deploy-2026-06-18`.
- Result: `PASS_PHASE_14J_LX_UI_LEGACY_COPY_CLEANUP_PLAN_NO_DEPLOY_DONE`.

## Source target

Selected active wrapper app source:

- `frontend/wrapper-ui/app.js`

Selection rule:

- exactly one JavaScript/TypeScript source file outside docs, smoke scripts, .git, and node_modules contained `privateStorageInfrastructureGroup`.

## Source changes

The repo-only patch removed active app source references to:

- `CT101 /api/* compatibility endpoints`
- `ct101-laptop-queue-worker`
- `Managed CT101 worker processing queued chat jobs`
- `master-laptop`
- `pveso`
- `ct-101`
- `CT101 for logged-in users`

The replacement source now uses current topology labels and IDs where needed:

- `ct-203`
- `pvew`
- `vm-200`

## Validation

Post-patch validation:

- `post_patch_legacy_hits=absent`
- `privateStorageInfrastructureGroup` marker present
- `Private backup storage policy:` marker present
- `ct-203` present
- `pvew` present
- `vm-200` present
- `node_syntax_check=pass`
- `app_source_sha_after=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`

## Mutation scope

Repo-only source/docs/smoke/commit/tag/push.

No frontend deploy, no VM200 write, no qemu guest-agent operation, no controller deploy, no CT203 source deploy, no service restart/reload/enable/start/stop, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no SSH connection attempt, no SSH config mutation, no Tailscale config/auth mutation, no PVESO wake/start, and no Cloudflare/DNS/tunnel mutation occurred.

## Future deployment boundary

A later frontend deployment to VM200 requires a separate explicit approval boundary.

Future deploy must:

1. deploy only the approved wrapper app asset;
2. parse qemu guest-agent JSON exitcode for VM200 operations;
3. verify deployed app sha256;
4. verify public app source version changes as expected;
5. verify storage card markers;
6. verify no active deployed app legacy hits;
7. verify public root and `/system/status`;
8. not change Cloudflare/DNS/tunnels;
9. not restart services unless separately approved.

## Result marker

`PASS_PHASE_14J_LY_UI_LEGACY_COPY_SOURCE_PATCH_NO_DEPLOY_DONE`
