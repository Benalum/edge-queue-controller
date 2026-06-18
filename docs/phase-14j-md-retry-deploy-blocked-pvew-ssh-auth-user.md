# Phase 14J-MD — Retry Deploy Blocked: PVEW SSH Auth/User Denied

Updated: 2026-06-18

## Purpose

This phase records the blocked Phase 14J-MD VM200 wrapper app asset deployment retry.

The retry was approved with:

`APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

The retry stopped before VM200 mutation because the workstation reached the PVEW Tailscale IP, but SSH authentication was denied for the default workstation user.

## Prior checkpoint

- Phase: 14J-MC — Update Workstation PVEW Alias to Tailscale IP Only.
- Commit: `4f3037e`.
- Tag: `controller-phase-14j-mc-update-workstation-pvew-alias-to-tailscale-ip-only-2026-06-18`.
- Result: `PASS_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY_DONE`.

## Blocked retry evidence

The approved retry validated before the block:

- repo was clean at `4f3037e`;
- repo app source hash was `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`;
- repo app legacy hits were absent;
- local `ssh -G pvew` succeeded;
- `ssh_g_hostname_prefix_100=yes`;
- `ssh_g_hostname_class=tailscale-ip-redacted`;
- `ssh_g_user_present=yes`;
- `ssh_g_port=22`;
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

The PVEW SSH preflight failed with:

`alex@<redacted-tailscale-ip>: Permission denied (publickey).`

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

No Tailscale config/auth mutation occurred.

No PVESO wake/start occurred.

## Interpretation

Phase 14J-MC fixed the previous DNS blocker: the local `Host pvew` alias now targets a Tailscale IPv4.

The remaining blocker is SSH authentication/user selection. The alias currently uses the default workstation SSH user, which expanded to `alex`; PVEW rejected that key/user combination.

For Proxmox host administration, the likely next local-only fix is to update the managed `Host pvew` block to use an explicitly configured operator user such as `root`, then validate with `ssh -G pvew` only. Any actual connection retry remains a separate deployment or connectivity gate.

## Next required gate

Suggested approval phrase:

`APPROVE_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY`

After that passes, retry deployment again with:

`APPROVE_PHASE_14J_MF_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_MD_RETRY_DEPLOY_BLOCKED_PVEW_SSH_AUTH_USER_DONE`
