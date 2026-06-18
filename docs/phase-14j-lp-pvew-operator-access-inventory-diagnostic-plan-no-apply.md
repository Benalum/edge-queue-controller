# Phase 14J-LP — PVEW Operator Access / Inventory Diagnostic Plan, No Apply

Updated: 2026-06-18

## Purpose

This phase records a no-apply plan for safely diagnosing why the operator workstation could not reach PVEW through the local `pvew` SSH alias during Phase 14J-LO.

The goal is to unblock future read-only host/CT203 backup inventory checks without mutating infrastructure, storage, services, CT/VM state, DBs, or public routes.

## Prior checkpoint

- Phase: 14J-LO — Read-Only Backup Inventory Shape Check.
- Commit: `be8eb3d`.
- Tag: `controller-phase-14j-lo-read-only-backup-inventory-shape-check-2026-06-18`.
- Result: `PASS_PHASE_14J_LO_READ_ONLY_BACKUP_INVENTORY_SHAPE_CHECK_RECORDED`.

## Problem observed

Phase 14J-LO public/repo checks passed, but the optional PVEW host/CT203 backup inventory section was skipped because:

`pvew_ssh=not_reachable_or_alias_missing`

This means the local operator workstation either did not have a usable `pvew` SSH alias or could not reach it during the check.

This was handled safely. No assumptions were made about:

- live host mount state;
- CT203 live DB metadata;
- backup file inventory;
- encrypted storage mount state;
- CT204 data role;
- PVESO state.

## Non-mutation guarantee

This phase is docs/smoke only.

It performs no:

- SSH attempt;
- live host query;
- DB mutation;
- DB backup creation;
- DB restore/import/migration;
- controller DB swap or data authority change;
- storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation;
- CT204 start, service activation, bind-mount role change, or data authority promotion;
- CT/VM config mutation;
- service restart, reload, enable, start, or stop;
- Cloudflare, DNS, tunnel, nginx public route, or public cutover mutation;
- PVESO wake/start or worker/model runtime activation.

## Diagnostic principles

Any future operator access diagnostic should:

1. Use read-only commands only.
2. Avoid printing private IPs, Tailscale IPs, MAC addresses, tokens, secrets, passwords, bearer values, auth URLs, or keys.
3. Avoid creating or editing SSH config unless explicitly approved.
4. Avoid starting PVESO or CT204.
5. Avoid unlocking or mounting private storage.
6. Avoid restarting or reloading CT203, VM200, nginx, cloudflared, or controller services.
7. Avoid Proxmox config mutation.
8. Avoid Cloudflare/DNS/tunnel mutation.
9. Treat missing alias as an operator-workstation issue, not a platform outage.
10. Keep CT203 as controller/API/queue authority until a separate approved authority boundary.

## Proposed future read-only diagnostic sequence

A later read-only diagnostic phase may inspect, without changing anything:

### A. Workstation local SSH alias presence

Read-only checks:

- whether `ssh -G pvew` resolves configuration;
- which hostname label is configured, with raw host values redacted;
- whether a `Host pvew` block exists in `~/.ssh/config`, without printing private addresses;
- whether required key file paths exist, without printing key material.

No SSH config edit should occur in this check.

### B. Workstation network reachability labels

Read-only checks:

- whether Tailscale is installed/running, with private IPs redacted;
- whether the operator has a known host alias or safe route label for PVEW;
- whether DNS or SSH alias resolution fails before any connection attempt.

No Tailscale login/auth/key operation should occur in this check.

### C. Optional PVEW SSH reachability

Only after A/B are safe, a later read-only check may attempt:

- `ssh -o BatchMode=yes -o ConnectTimeout=5 pvew true`

The output must not print raw hostnames, IPs, MACs, tokens, auth URLs, or secrets.

### D. Optional PVEW inventory after reachability

Only if SSH reachability succeeds, a later read-only check may collect shallow metadata:

- VM200 status expected `running`;
- CT203 status expected `running`;
- CT204 status expected `stopped`;
- CT203 DB existence, size, mtime, and SQLite integrity result;
- candidate backup directory existence and shallow file metadata;
- private storage mountpoint existence and `findmnt` summary, without mounting or unlocking anything.

This must remain read-only. It must not create backups or restore DBs.

## Stop conditions

Stop immediately and do not proceed to host/CT inventory if any of the following are true:

- repo is dirty;
- public `/system/status` is not HTTP 200;
- public overall state is not `online`;
- public node model does not include `ct-203,ct-204,pvew,vm-200`;
- CT204 public status is not stopped/non-authority;
- the diagnostic would require a login/auth URL, token, password, key change, or new credential;
- the diagnostic would require changing SSH config, Tailscale config, Proxmox config, storage, services, DBs, CTs/VMs, or Cloudflare/DNS/tunnels.

## Future branch options

After this plan is committed, safe next branches are:

1. Phase 14J-LQ — read-only workstation SSH alias diagnostic, no apply.
2. Phase 14J-LR — CT204 backup-data role no-apply design.
3. Phase 14J-LS — isolated restore-drill no-apply design.
4. Status/UI polish.

Any live backup creation, DB restore/import/migration, CT204 start, storage unlock/mount, service restart, or route/tunnel mutation requires explicit approval.

## Result marker

`PASS_PHASE_14J_LP_PVEW_OPERATOR_ACCESS_INVENTORY_DIAGNOSTIC_PLAN_NO_APPLY_DONE`
