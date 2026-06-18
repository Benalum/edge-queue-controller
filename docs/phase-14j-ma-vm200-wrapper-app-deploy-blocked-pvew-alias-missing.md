# Phase 14J-MA — VM200 Wrapper App Deploy Blocked: PVEW Alias Missing

Updated: 2026-06-18

## Purpose

This phase records the blocked Phase 14J-MA deployment attempt.

The deployment was approved with:

`APPROVE_PHASE_14J_MA_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

The deploy block stopped before VM200 mutation because the workstation could not resolve the `pvew` SSH target.

## Prior checkpoint

- Phase: 14J-LZ — UI Deploy Readiness Review, No Deploy.
- Commit: `64f29c6`.
- Tag: `controller-phase-14j-lz-ui-deploy-readiness-review-no-deploy-2026-06-18`.
- Result: `PASS_PHASE_14J_LZ_UI_DEPLOY_READINESS_REVIEW_NO_DEPLOY_DONE`.

## Blocked attempt evidence

The approved deploy preflight validated:

- repo was clean at `64f29c6`;
- repo app source hash was `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`;
- repo app legacy hits were absent;
- public root was HTTP 200;
- public app source was `/app.js?v=2026061814jlbr2`;
- public app hash before deploy was `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`;
- public deployed legacy hit count before deploy was `10`;
- public `/system/status` was HTTP 200;
- `overall_state_before=online`;
- `normalized_schema_version_before=2`;
- `node_ids_sorted_before=ct-203,ct-204,pvew,vm-200`;
- `storage_policy_before=manual-unlock-only`;
- `storage_mount_state_before=unknown`;
- `ct204_expected_state_before=stopped`;
- `ct204_data_authority_before=false`.

The PVEW/qemu guest-agent preflight failed with:

`ssh: Could not resolve hostname pvew: Temporary failure in name resolution`

The deployment then stopped with:

`FAIL: PVEW SSH/qemu guest-agent preflight failed; no deploy performed`

## Mutation result

No VM200 write occurred.

No qemu guest-agent operation reached VM200.

No frontend deploy occurred.

No index.html mutation occurred.

No nginx config mutation occurred.

No cloudflared config mutation occurred.

No Cloudflare/DNS/tunnel mutation occurred.

No service restart/reload/enable/start/stop occurred.

No controller deploy occurred.

No CT203 source deploy occurred.

No DB mutation, backup creation, restore, import, or migration occurred.

No storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation occurred.

No CT204 start or data authority change occurred.

No CT/VM config mutation occurred.

No SSH config mutation occurred.

No Tailscale config/auth mutation occurred.

No PVESO wake/start occurred.

## Interpretation

The repo source is ready for deployment, but the workstation still lacks a usable `Host pvew` alias or equivalent PVEW SSH target.

This matches the earlier Phase 14J-LQ finding:

- `ssh_config_host_pvew_block=missing`
- `ssh_g_hostname_class=literal-pvew-no-hostname-override`
- `tailscale_pvew_peer_hint=present-redacted`
- `diagnostic_result=pvew_ssh_alias_missing_or_unconfigured`

## Next required gate

Before retrying the VM200 wrapper app asset deploy, add a workstation `Host pvew` alias or provide another known-safe PVEW SSH target.

Suggested approval phrase:

`APPROVE_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY`

After that passes, retry:

`APPROVE_PHASE_14J_MB_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_MA_VM200_WRAPPER_APP_DEPLOY_BLOCKED_PVEW_ALIAS_MISSING_DONE`
