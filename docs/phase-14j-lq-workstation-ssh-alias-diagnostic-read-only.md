# Phase 14J-LQ — Workstation SSH Alias Diagnostic, Read Only

Updated: 2026-06-18

## Purpose

This phase records the read-only workstation-side SSH/Tailscale diagnostic performed after Phase 14J-LP.

The goal was to determine why Phase 14J-LO could not reach PVEW through the local `pvew` SSH alias, without connecting to PVEW and without mutating workstation SSH config, Tailscale config, infrastructure, services, DBs, storage, CT204, PVESO, or public routes.

## Prior checkpoint

- Phase: 14J-LP — PVEW Operator Access / Inventory Diagnostic Plan, No Apply.
- Commit: `ef01858`.
- Tag: `controller-phase-14j-lp-pvew-operator-access-inventory-diagnostic-plan-no-apply-2026-06-18`.
- Result: `PASS_PHASE_14J_LP_PVEW_OPERATOR_ACCESS_INVENTORY_DIAGNOSTIC_PLAN_NO_APPLY_DONE`.

## Mutation scope

This phase is evidence/docs/smoke only.

It records a read-only diagnostic that performed no:

- repo mutation during the diagnostic run;
- live infrastructure mutation;
- SSH connection attempt;
- SSH config mutation;
- Tailscale config/auth mutation;
- DB mutation;
- DB backup creation;
- DB restore/import/migration;
- storage unlock/mount/format/key/crypttab/fstab mutation;
- CT/VM config mutation;
- CT204 start or data authority change;
- PVESO wake/start;
- service restart/reload/enable/start/stop;
- Cloudflare/DNS/tunnel mutation.

This checkpoint commit only records the evidence and smoke script in git.

## Public status guard observed

The public status guard remained healthy before the workstation diagnostic:

- `public_system_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

## Workstation SSH diagnostic observed

Read-only local SSH config expansion showed:

- `ssh_config_exists=yes`
- `ssh_config_host_pvew_block=missing`
- `ssh_binary=present`
- `ssh_g_pvew_exitcode=0`
- `ssh_g_hostname_class=literal-pvew-no-hostname-override`
- `ssh_g_user_present=yes`
- `ssh_g_port=22`
- `ssh_g_identityfile_count=7`
- `ssh_g_proxyjump_present=no`
- `ssh_g_proxycommand_present=no`

Interpretation:

- `ssh -G pvew` succeeded because local SSH can expand default settings for any hostname.
- The hostname remained the literal label `pvew`, so there is no configured alias mapping `pvew` to a reachable PVEW host label/address.
- No SSH connection was attempted.

## Workstation Tailscale diagnostic observed

Read-only local Tailscale daemon status showed:

- `tailscale_binary=present`
- `tailscale_status_json_exitcode=0`
- `tailscale_backend_state=Running`
- `tailscale_peer_count=5`
- `tailscale_pvew_peer_hint=present-redacted`

Interpretation:

- Tailscale is running on the workstation.
- A redacted PVEW peer hint exists.
- The blocker is likely local SSH alias configuration rather than absence of a PVEW Tailscale peer.
- Raw Tailscale IPs, peer DNS names, MACs, auth URLs, and secrets were not printed.

## Diagnostic result

Final classification:

`diagnostic_result=pvew_ssh_alias_missing_or_unconfigured`

## Meaning

The operator workstation likely needs a safe `Host pvew` alias or the project needs to use a different known-safe PVEW host label for read-only inventory checks.

This does not indicate that the public platform is down. Public `/system/status` remained online and the current public node model remained valid.

## Guardrails retained

- CT203 remains the controller/API/queue authority.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Private encrypted storage remains manual-unlock-only.
- Public storage mount state remains `unknown`.
- CT203 must not inspect/control live host mount state through public status.
- VM200 remains public/static only.
- PVESO remains parked/on-demand.
- No SSH alias was added by this phase.
- No SSH connection was attempted by this phase.
- No storage/DB/service/route/authority mutation occurred.

## Recommended next steps

Safe next options:

1. Phase 14J-LR — repo-only plan for adding a workstation `Host pvew` SSH alias.
2. Phase 14J-LS — read-only Tailscale peer-label extraction plan with sensitive values redacted.
3. A separate explicit approval boundary to add a `Host pvew` alias to workstation SSH config using a known-safe PVEW Tailscale DNS label or host label.
4. CT204 backup-data role no-apply design.
5. Isolated restore-drill no-apply design.

Do not edit SSH config, connect to PVEW, create backups, restore DBs, unlock/mount storage, start CT204, wake PVESO, restart services, or change Cloudflare/DNS/tunnels without the appropriate explicit boundary.

## Result marker

`PASS_PHASE_14J_LQ_WORKSTATION_SSH_ALIAS_DIAGNOSTIC_READ_ONLY_RECORDED`
