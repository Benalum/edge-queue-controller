# Phase 14J-LU — CT204 Backup-Data Role Design, No Apply

Updated: 2026-06-18

## Purpose

This phase records a no-apply design for CT204 as a future backup-data helper only.

It does not start CT204, promote CT204, create backups, restore DBs, mutate storage, unlock or mount encrypted private storage, change services, change CT/VM configuration, connect over SSH, wake PVESO, or change Cloudflare/DNS/tunnels.

## Prior checkpoint

- Phase: 14J-LR — Workstation PVEW SSH Alias Add Plan, No Apply.
- Commit: `eab99eb`.
- Tag: `controller-phase-14j-lr-workstation-pvew-ssh-alias-add-plan-no-apply-2026-06-18`.
- Result: `PASS_PHASE_14J_LR_WORKSTATION_PVEW_SSH_ALIAS_ADD_PLAN_NO_APPLY_DONE`.

## Current baseline assumptions

- CT203 remains the live controller/API/queue authority.
- CT203 active DB remains `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Public CT204 expected state remains `stopped`.
- Public CT204 data authority remains `false`.
- PVEW private encrypted storage remains manual-unlock-only.
- Public private storage mount state remains `unknown`.
- PVESO remains parked/on-demand.

## Non-mutation guarantee

This phase is docs/smoke only.

It performs no:

- CT204 start;
- CT204 onboot change;
- CT204 service activation;
- CT204 bind-mount role change;
- CT204 data authority promotion;
- CT/VM config mutation;
- DB mutation;
- DB backup creation;
- DB restore/import/migration;
- controller DB swap;
- storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation;
- SSH connection attempt;
- SSH config mutation;
- Tailscale config/auth mutation;
- service restart/reload/enable/start/stop;
- PVESO wake/start;
- Cloudflare/DNS/tunnel mutation.

## CT204 intended future role

CT204 should remain a backup-data helper candidate, not authority.

Allowed future concepts, only after separate approval:

1. Store backup copies or backup indexes.
2. Validate backup files in isolation.
3. Support restore-drill staging without touching CT203 live DB.
4. Maintain clear metadata showing it is not the live controller/API/queue authority.
5. Remain excluded from public authority claims unless explicitly promoted later.

Forbidden without separate explicit approval:

1. Starting CT204.
2. Enabling CT204 onboot.
3. Running controller/API/queue authority services on CT204.
4. Importing/restoring CT203 DB into a live authority path.
5. Mounting private storage into CT204.
6. Changing bind mounts.
7. Creating automatic storage unlock or mount units.
8. Changing public status to show CT204 as authority.
9. Changing Cloudflare/DNS/tunnel routing to CT204.

## Required preconditions before any CT204 live work

Before any future CT204 start or data role work, require:

1. Clean repo and current Source checkpoint.
2. Public `/system/status` online.
3. CT203 confirmed authority and DB integrity confirmed.
4. Fresh CT203 backup plan or approved backup operation.
5. Restore rollback plan written.
6. CT204 exact role written: backup-data-only, restore-drill-only, or authority-promotion candidate.
7. Explicit approval phrase for the exact CT204 mutation.
8. Stop conditions written before execution.
9. Sanitized output rules active.

## Future CT204 explicit approval boundaries

Potential future approval phrases:

- `APPROVE_PHASE_14J_LV_START_CT204_READ_ONLY_INSPECTION_ONLY`
- `APPROVE_PHASE_14J_LW_CT204_BACKUP_METADATA_INSPECTION_ONLY`
- `APPROVE_PHASE_14J_LX_CT204_ISOLATED_RESTORE_DRILL_ONLY`
- `APPROVE_PHASE_14J_LY_CT204_AUTHORITY_PROMOTION_PLAN_ONLY`

Each phrase must still be paired with a narrow PPB block that states all non-scope items.

## Stop conditions

Stop before any CT204 live step if:

- repo is dirty;
- public `/system/status` is not online;
- CT203 authority is unclear;
- CT203 DB integrity is not confirmed;
- private storage state is unclear and the operation depends on it;
- CT204 would become authority accidentally;
- a command would start/restart services outside the approved scope;
- secrets, keys, tokens, raw private IPs, MACs, or auth URLs would be printed;
- the operation requires Cloudflare/DNS/tunnel mutation;
- the operation requires PVESO wake/start.

## Relationship to SSH alias work

Phase 14J-LR showed that a workstation `Host pvew` alias needs a separate approval before editing SSH config.

CT204 planning can continue without adding that alias, but real PVEW/CT204 host-side inspection will eventually require either:

1. an approved workstation SSH alias add; or
2. another known-safe reachable PVEW access path with sanitized output.

## Recommended next phases

Safe next options:

1. Phase 14J-LV — isolated restore-drill no-apply design.
2. Phase 14J-LW — status/UI polish no-apply review.
3. Approved Phase 14J-LS — add workstation `Host pvew` alias only.
4. Approved Phase 14J-LV — start CT204 read-only inspection only.

Any CT204 start, DB backup, DB restore, storage unlock/mount, service restart, SSH config edit, SSH connection, PVESO wake, or route/tunnel mutation requires a separate explicit approval boundary.

## Result marker

`PASS_PHASE_14J_LU_CT204_BACKUP_DATA_ROLE_NO_APPLY_DONE`
