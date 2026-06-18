# Phase 14J-MC — Update Workstation PVEW Alias to Tailscale IP Only

Updated: 2026-06-18

## Purpose

This phase updated only the local workstation managed `Host pvew` SSH alias so its `HostName` uses the PVEW Tailscale IPv4 address instead of the non-resolving Tailscale DNS name.

## Approval

`APPROVE_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY`

## Prior checkpoint

- Phase: 14J-MB — Retry Deploy Blocked: PVEW Tailscale DNS Resolution.
- Commit: `3d0cfce`.
- Tag: `controller-phase-14j-mb-retry-deploy-blocked-pvew-dns-resolution-2026-06-18`.
- Result: `PASS_PHASE_14J_MB_RETRY_DEPLOY_BLOCKED_PVEW_DNS_RESOLUTION_DONE`.

## Mutation scope

Allowed mutation:

- local workstation `~/.ssh/config` managed `Host pvew` block `HostName` line only.

No SSH connection attempt, no qemu guest-agent operation, no VM200 write, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Discovery evidence

- `tailscale_backend_state=Running`
- `pvew_peer_match_count=1`
- `pvew_tailscale_ipv4_found=yes`
- `pvew_alias_target_class=tailscale-ip-redacted`
- `pvew_alias_target_ipv4_prefix_100=yes`

The raw PVEW Tailscale IP was intentionally not printed or committed.

## SSH config evidence

- `managed_begin_count=1`
- `managed_end_count=1`
- `managed_block_has_host_pvew=yes`
- `managed_block_hostname_line_count=1`
- `ssh_config_backup_path=/home/alex/.ssh/config.bak-phase-14j-mc-20260618T223331Z`
- `ssh_config_managed_host_pvew_hostname_updated=yes`

## Local config expansion validation

`ssh -G pvew` was used only for local config expansion. It does not connect to PVEW.

- `ssh_g_pvew_exitcode=0`
- `ssh_g_hostname_matches_tailscale_ip=yes`
- `ssh_g_hostname_prefix_100=yes`
- `ssh_g_hostname_class=tailscale-ip-redacted`
- `ssh_g_user_present=yes`
- `ssh_g_port=22`
- `ssh_g_proxyjump_present=no`
- `ssh_g_proxycommand_present=no`

## Next gate

The VM200 wrapper app asset deploy can be retried only with a separate explicit approval phrase:

`APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY_DONE`
