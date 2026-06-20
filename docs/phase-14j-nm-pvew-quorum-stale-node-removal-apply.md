# Phase 14J-NM — PVEW Quorum Stale-Node Removal Apply

Date: 2026-06-19  
Scope: guarded PVEW quorum cleanup apply and documentation checkpoint.

## Result

Phase 14J-NM completed after staged recovery:

- `pve` stale node was removed through `pvecm delnode pve`.
- `pveso` stale node could not be removed through repeated `pvecm delnode pveso` attempts.
- PVEW was temporarily restored to quorum with `pvecm expected 1` during recovery.
- The remaining stale `pveso` corosync node stanza was removed manually from `/etc/pve/corosync.conf`.
- `config_version` was incremented from 4 to 5.
- `corosync-cfgtool -R` reloaded the corosync config successfully.
- Final corosync config contains only `pvew`.
- Final quorum state is PVEW-only, quorate, expected votes 1, total votes 1.

## Final live invariants

- PVEW remains online.
- VM200 remains running.
- CT203 remains running.
- CT204 remains stopped.
- Private storage remains locked/unmounted.
- `/dev/mapper/apc_private_data` remains absent.
- CT203 controller health remains available.
- Public `/` remains HTTP 200.
- Public `/system/status` remains HTTP 200.
- Public `/api/me` remains HTTP 401 unauthenticated, expected.
- `/etc/pve/nodes/pveso` guest config directory was not deleted.
- No PVEW reboot was performed.
- No VM/CT restart was performed.
- No nginx/cloudflared reload or restart was performed.
- No CT203 address change was performed.
- No private storage unlock/mount was performed.
- No CT204 start was performed.
- No worker/model/scheduler activation was performed.
- No DB mutation was performed.
- No Cloudflare/DNS/tunnel mutation was performed.
- No PVESO mutation was performed.

## Backup locations

Backups were created under `/root/apc-quorum-backups/` for:

- initial NM attempt
- NM-R2 regain-quorum attempt
- NM-R3/R3B/R3C generator attempts
- final NM-R3D successful manual corosync cleanup

## Important note

The system is now quorate and public-serving, but reboot durability has not yet been proven. A PVEW reboot/autostart validation must be a separate explicit approval phase.

## Next recommended phase

Phase 14J-NO should be a no-apply reboot readiness checkpoint. It should verify that:

- PVEW corosync config remains pvew-only.
- VM200 and CT203 are onboot=1.
- CT204 is onboot=0.
- private storage remains manual-unlock-only.
- public health is good before reboot testing.

Actual reboot testing should require a separate approval.
