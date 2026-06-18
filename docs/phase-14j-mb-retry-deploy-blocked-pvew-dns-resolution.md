# Phase 14J-MB — Retry Deploy Blocked: PVEW Tailscale DNS Resolution

Updated: 2026-06-18

## Purpose

This phase records the blocked Phase 14J-MB VM200 wrapper app asset deployment retry.

The retry was approved with:

`APPROVE_PHASE_14J_MB_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

The retry stopped before VM200 mutation because the local `Host pvew` alias expanded to a redacted Tailscale DNS hostname that the workstation resolver could not resolve.

## Prior checkpoint

- Phase: 14J-LS — Add Workstation PVEW SSH Alias Only.
- Commit: `f1b0cb7`.
- Tag: `controller-phase-14j-ls-add-workstation-pvew-ssh-alias-only-2026-06-18`.
- Result: `PASS_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY_DONE`.

## Blocked retry evidence

The approved retry validated before the block:

- repo was clean at `f1b0cb7`;
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

The PVEW SSH preflight failed with:

`ssh: Could not resolve hostname <redacted-tailscale-dns>: Name or service not known`

The phase exited with:

`phase_exit_code=255`

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

Phase 14J-LS successfully added a local `Host pvew` block and validated local `ssh -G pvew` expansion.

However, the selected redacted Tailscale DNS target does not resolve through the workstation resolver.

The next safe fix is a separate local-only SSH alias update that uses the PVEW Tailscale IP from local `tailscale status --json`, without printing the raw IP.

## Next required gate

Suggested approval phrase:

`APPROVE_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY`

After that passes, retry deployment again with:

`APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_MB_RETRY_DEPLOY_BLOCKED_PVEW_DNS_RESOLUTION_DONE`
