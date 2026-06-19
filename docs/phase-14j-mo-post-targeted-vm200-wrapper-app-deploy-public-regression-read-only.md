# Phase 14J-MO — Post-Targeted VM200 Wrapper App Deploy Public Regression Read-Only

Updated: 2026-06-18

## Purpose

This phase records a read-only public regression checkpoint after Phase 14J-MN targeted VM200 wrapper `app.js` deployment.

## Prior checkpoint

- Phase: 14J-MN — Targeted VM200 Wrapper App Asset Deploy.
- Commit: `156db84`.
- Tag: `controller-phase-14j-mn-retry-deploy-vm200-wrapper-app-asset-only-target-var-www-apc-wrapper-local-2026-06-18`.
- Result: `PASS_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL_DONE`.

## Public wrapper regression evidence

- `repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `repo_app_legacy_hits=absent`
- `repo_node_syntax_check=pass`
- `public_root_http=200`
- `public_app_src=/app.js?v=2026061814jlbr2`
- `public_app_sha_cache_busted=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `public_app_legacy_hits=absent`
- `public_root_html_legacy_hits=absent`

## Public status regression evidence

- `public_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `storage_mountpoint=/srv/apc-private-data`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

## Confirmed live app target from previous phase

- VM200 live wrapper app path: `/var/www/apc-wrapper-local/app.js`
- VM200 live wrapper index path: `/var/www/apc-wrapper-local/index.html`

## Safety posture retained

- CT203 remains controller/API/queue authority.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Private storage remains manual-unlock-only.
- Public private storage mount_state remains unknown.
- PVESO remains parked/on-demand.
- Cloudflare/DNS/tunnels were not changed.
- Services were not restarted or reloaded.

## Mutation scope

No SSH connection, no VM200 write, no qemu guest-agent operation, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Result marker

`PASS_PHASE_14J_MO_POST_TARGETED_VM200_WRAPPER_APP_DEPLOY_PUBLIC_REGRESSION_READ_ONLY_DONE`
