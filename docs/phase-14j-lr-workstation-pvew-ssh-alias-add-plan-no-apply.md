# Phase 14J-LR — Workstation PVEW SSH Alias Add Plan, No Apply

Updated: 2026-06-18

## Purpose

This phase records a no-apply plan for adding a safe workstation `Host pvew` SSH alias later.

It does not edit `~/.ssh/config`, connect to PVEW, change Tailscale, mutate infrastructure, create backups, restore DBs, unlock storage, start CT204, wake PVESO, restart services, or change public routes.

## Prior checkpoint

- Phase: 14J-LQ — Workstation SSH Alias Diagnostic, Read Only.
- Commit: `0106a29`.
- Tag: `controller-phase-14j-lq-workstation-ssh-alias-diagnostic-read-only-2026-06-18`.
- Result: `PASS_PHASE_14J_LQ_WORKSTATION_SSH_ALIAS_DIAGNOSTIC_READ_ONLY_RECORDED`.

## Observed blocker from 14J-LQ

The workstation-side diagnostic found:

- `ssh_config_exists=yes`
- `ssh_config_host_pvew_block=missing`
- `ssh_g_hostname_class=literal-pvew-no-hostname-override`
- `tailscale_backend_state=Running`
- `tailscale_peer_count=5`
- `tailscale_pvew_peer_hint=present-redacted`
- `diagnostic_result=pvew_ssh_alias_missing_or_unconfigured`

Interpretation:

- The public platform is online.
- Tailscale is running on the operator workstation.
- A redacted PVEW peer hint exists.
- The blocker is a missing local SSH alias, not a proven PVEW outage.

## Non-mutation guarantee

This phase is docs/smoke only.

It performs no:

- SSH connection attempt;
- SSH config mutation;
- Tailscale config/auth mutation;
- DB mutation;
- DB backup creation;
- DB restore/import/migration;
- storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation;
- CT/VM config mutation;
- CT204 start, service activation, bind-mount role change, or data authority promotion;
- PVESO wake/start;
- service restart/reload/enable/start/stop;
- Cloudflare/DNS/tunnel mutation.

## Future explicit approval boundary

Adding the alias is a workstation config mutation and should require a separate approval phrase.

Suggested approval phrase:

`APPROVE_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY`

Allowed scope after approval:

- Backup the existing `~/.ssh/config` to a timestamped local backup file.
- Add or replace only the `Host pvew` block.
- Use a known-safe PVEW Tailscale DNS label or host label supplied by the operator or discovered in a redacted, read-only way.
- Set only narrow SSH client options needed for operator access.
- Run `ssh -G pvew` after the edit to verify local config expansion.
- Do not connect to PVEW unless separately approved.

Explicit non-scope:

- No SSH connection attempt.
- No Tailscale auth/login/key mutation.
- No Proxmox mutation.
- No CT/VM start/stop/config mutation.
- No service restart/reload/enable/start/stop.
- No DB backup/create/restore/import/migration.
- No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation.
- No Cloudflare/DNS/tunnel mutation.
- No PVESO wake/start.
- No CT204 start or data authority change.

## Proposed alias shape

The future alias should be minimal and not include secrets:

```sshconfig
Host pvew
    HostName <PVEW_TAILSCALE_DNS_OR_SAFE_HOST_LABEL>
    User <PVEW_OPERATOR_USER>
    Port 22
    IdentitiesOnly noRun with Project Pilot
Run with Project Pilot

Notes:

<PVEW_TAILSCALE_DNS_OR_SAFE_HOST_LABEL> must not be committed.
<PVEW_OPERATOR_USER> should be the operator account used for PVEW admin access.
Do not print private IPs, Tailscale IPs, raw DNS names, MACs, tokens, passwords, keys, auth URLs, bearer values, or secrets in terminal output.
Do not store keys or secrets in repo docs.
Validation after future alias add

After the approved alias edit, validate only local expansion first:

ssh -G pvew exit code is 0.
hostname class is no longer literal-pvew-no-hostname-override.
user is present.
port is 22.
no raw hostname/IP/key material is printed.

Only after that should a separate read-only SSH reachability check be considered.

Next phase options

Safe next options:

Phase 14J-LS — approved workstation SSH alias add only.
Phase 14J-LT — no-apply read-only PVEW SSH reachability plan.
Phase 14J-LU — CT204 backup-data role no-apply design.
Phase 14J-LV — isolated restore-drill no-apply design.

Any live SSH connection, DB backup, restore, CT204 start, storage unlock/mount, service restart, PVESO wake, or route/tunnel mutation requires its own explicit approval boundary.

Result marker

PASS_PHASE_14J_LR_WORKSTATION_PVEW_SSH_ALIAS_ADD_PLAN_NO_APPLY_DONE
