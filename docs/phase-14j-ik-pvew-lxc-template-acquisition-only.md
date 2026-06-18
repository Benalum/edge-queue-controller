# Phase 14J-IK - PVEW LXC Template Acquisition Only

## Scope

This phase records the approved PVEW LXC template acquisition boundary.

The approved mutation was limited to refreshing/listing Proxmox LXC templates if needed and downloading one approved Debian standard LXC template into the PVEW local template cache.

This phase did not approve or perform CT203/CT204 creation, CT start, CT clone, CT delete, storage creation, storage formatting, storage mounting, storage resizing, encryption setup, key generation, DB dump/copy/import/migration, service activation, onboot/autostart mutation, VM200 mutation, PVESO power action, public route mutation, Cloudflare/DNS/tunnel mutation, CT101 call, model call, worker start, or production DB/job mutation.

## Pre-download guard

The guard verified:

- repo head was `cc0730f`;
- repo tree was clean;
- laptop DB quick_check was `ok`;
- PVEW was reachable;
- VM200 `website-edge` was running;
- CT203 was unused;
- CT204 was unused.

## Template result

Downloaded template:

`debian-13-standard_13.1-2_amd64.tar.zst`

Destination:

`/var/lib/vz/template/cache/debian-13-standard_13.1-2_amd64.tar.zst`

The Proxmox checksum verification completed successfully.

## Post-download guard

After template acquisition:

- VM200 `website-edge` remained running;
- CT203 remained unused;
- CT204 remained unused;
- no CT203/CT204 creation occurred;
- no encrypted storage was created;
- no encryption key was generated, printed, installed, or stored;
- no user/platform DB data was copied, dumped, imported, migrated, or output.

## Next allowed direction

Return to the previously approved CT203/CT204 private candidate creation boundary, using the acquired Debian standard LXC template.

Creation must still be limited to private, non-authoritative candidates only.

## Result

`PASS_PVEW_TEMPLATE_ACQUIRED_ONLY_CT203_CT204_NOT_CREATED`
