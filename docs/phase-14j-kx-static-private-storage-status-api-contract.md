# Phase 14J-KX — Static private storage status API contract

Date: 2026-06-18

## Scope

Repo-only source/docs/smoke patch. No live service reload or runtime activation.

## Change

Add a public-safe `private_storage_status` block to `/system/status`.

The block intentionally reports:

- `mount_state: unknown`
- `policy: manual-unlock-only`
- `mountpoint: /srv/apc-private-data`
- CT204 expected state: stopped
- CT204 data authority: false

## Rationale

CT203 cannot directly inspect the PVEW host encrypted mount without a separately approved host-visible signal, bind mount, or host probe.

This patch avoids pretending the mount is visible from CT203. It exposes only the current storage policy and explicitly reports live mount state as unknown.

## Explicitly not changed

- No live service reload.
- No storage mutation.
- No crypttab/fstab/systemd mutation.
- No keyfile creation.
- No CT/VM mutation.
- No DB mutation.
- No host mount probing.
