# Phase 14J-MN — Targeted VM200 Wrapper App Asset Deploy

Updated: 2026-06-18

## Purpose

This phase completed the targeted VM200 wrapper `app.js` asset deployment using the confirmed live path from Phase 14J-MM.

## Approval

`APPROVE_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL`

## Prior checkpoint

- Phase: 14J-MM — VM200 Webroot App Path Read-Only Diagnostic.
- Commit: `3d0b10f`.
- Tag: `controller-phase-14j-mm-vm200-webroot-app-path-read-only-diagnostic-2026-06-18`.
- Result: `PASS_PHASE_14J_MM_VM200_WEBROOT_APP_PATH_READ_ONLY_DIAGNOSTIC_DONE`.

## Mutation scope

Allowed mutation:

- VM200 single-file wrapper asset replacement only: `/var/www/apc-wrapper-local/app.js`.

No SSH config mutation, no frontend deploy beyond single app.js asset, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation except VM200 `/var/www/apc-wrapper-local/app.js` file replacement, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Repo source

- `repo_app_source=frontend/wrapper-ui/app.js`
- `repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `repo_app_legacy_hits=absent`
- `repo_node_syntax_check=pass`

## Targeted VM200 deployment evidence

- `target_path=/var/www/apc-wrapper-local/app.js`
- `index_path=/var/www/apc-wrapper-local/index.html`
- `remote_deploy_mode=synchronous_guest_exec_no_pid`
- `guest_targetcheck_exitcode=0`
- `guest_deploy_exitcode=0`
- `asset_source=github_raw_commit`
- `vm200_app_sha_before=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `vm200_app_sha_after=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `vm200_app_legacy_hits=absent`

qemu guest-agent exitcode parsing was required and performed for all guest exec operations.

## Public validation after deploy

- `public_root_http_after=200`
- `public_app_src_after=/app.js?v=2026061814jlbr2`
- `public_app_sha_after_cache_busted=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `public_deployed_legacy_hits_after=absent`
- `public_status_http_after=200`
- `overall_state_after=online`
- `normalized_schema_version_after=2`
- `node_ids_sorted_after=ct-203,ct-204,pvew,vm-200`
- `storage_policy_after=manual-unlock-only`
- `storage_mount_state_after=unknown`
- `ct204_expected_state_after=stopped`
- `ct204_data_authority_after=false`

## Safety posture retained

- CT203 remains controller/API/queue authority.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Private storage remains manual-unlock-only.
- Public private storage mount_state remains unknown.
- PVESO remains parked/on-demand.
- Cloudflare/DNS/tunnels were not changed.
- Services were not restarted or reloaded.

## Result marker

`PASS_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL_DONE`
