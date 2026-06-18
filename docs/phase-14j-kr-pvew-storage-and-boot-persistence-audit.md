# Phase 14J-KR — PVEW storage and boot persistence audit

Date: 2026-06-18

## Scope

This checkpoint records a read-only audit of PVEW storage, quorum, boot persistence, encrypted backup posture, and CT203 DB health after the PVEW-contained public controller repair.

## Verified quorum state

PVEW is currently operating as a single-node Proxmox cluster member:

- Cluster name: `ClusterOfThings`
- Nodes: `1`
- Expected votes: `1`
- Total votes: `1`
- Quorum: `1`
- Quorate: `Yes`

This is currently healthy for a single-node PVEW operating posture, but should be revisited before adding or rejoining nodes.

## Verified VM/CT boot posture

VM200 `website-edge`:

- Status: running
- `onboot: 1`
- Role: public edge/static/nginx/cloudflared bridge

CT203 `edge-controller-pvew`:

- Status: running
- `onboot: 1`
- `edge-queue-controller.service`: active
- `edge-queue-controller.service`: enabled
- Role: private controller/API/queue candidate

CT204 `edge-data-pvew`:

- Status: stopped
- `onboot: 0`
- Bind mount: `/srv/apc-private-data/ct204` to `/mnt/apc-private-data`, read-only
- Role: private encrypted data/backups candidate only
- Not live data authority

## Verified encrypted storage posture

Encrypted private storage is currently mounted:

- Mountpoint: `/srv/apc-private-data`
- Mapper: `/dev/mapper/apc_private_data`
- Filesystem: ext4
- Mode: read/write
- LUKS type: LUKS2
- Cipher: aes-xts-plain64
- Key size: 512 bits

## Persistence audit

No automatic encrypted storage unlock or mount persistence was found:

- `/etc/crypttab`: no APC/private/LUKS entry
- `/etc/fstab`: no APC/private/LUKS mount entry
- `/etc/systemd/system`: no relevant APC/private/crypt unit found

Manual helper exists:

- `/root/apc-private-storage-unlock-mount.sh`
- mode: `700`
- owner: `root:root`

## Backup inventory

Encrypted backup storage currently contains:

- Laptop/controller historical backup:
  - `/srv/apc-private-data/ct204/backups/controller-laptop/edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3`

- Fresh CT203 controller backup:
  - `/srv/apc-private-data/ct204/backups/ct203-controller/edge_queue_ct203_backup_20260618T185019Z_head-8044621.sqlite3`
  - `/srv/apc-private-data/ct204/backups/ct203-controller/edge_queue_ct203_backup_20260618T185019Z_head-8044621.sqlite3.manifest`

## CT203 DB health

CT203 controller DB:

- Path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- Size: `43794432`
- Mode: `600`
- Owner: `root:root`
- Integrity: `ok`

## Interpretation

The public platform is boot-persistent at the VM200 and CT203 service level, but encrypted backup storage is intentionally manual after reboot. After a reboot, VM200 and CT203 should come back automatically, but `/srv/apc-private-data` and CT204 backup access require manual unlock/mount unless a later explicitly approved persistence design is applied.

## Follow-up

Recommended next no-apply design phase:

- Decide whether encrypted storage should remain manual-unlock only, or
- add a gated boot-time mount policy that still avoids storing passphrases or secrets on disk.

No storage persistence should be changed without separate explicit approval.
