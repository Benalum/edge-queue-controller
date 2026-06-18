# Phase 14J-JN - PVEW-Contained Platform Pivot, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase records the project-direction pivot: stop designing around the laptop as long-term live controller/website authority, and instead move toward a PVEW-contained platform where the website, controller/API, queue data, private backups, and supporting containers run from PVEW.

This phase does not mutate CT config, add bind mounts, start containers, restore/import data, move controller authority, change website routes, mutate Cloudflare/DNS/tunnels, mutate Proxmox storage, mutate persistence, or wake PVESO.

## User direction

User direction:

- Get the website/platform working from containers.
- Do not keep the laptop in the live authority path.
- Use the laptop later only as an optional worker.

## Superseded near-term path

The previously prepared CT204 read-only bind-mount apply should not be run yet.

Reason:

- It is safe and small, but it does not directly get the website working sooner.
- The faster path is to baseline CT203/CT204/VM200 and design the minimum PVEW-contained runtime needed to restore the website.
- CT204 private storage remains useful, but it should support the PVEW-contained platform rather than continue as an isolated migration exercise.

## Target end-state

PVEW target role:

- VM200: public website edge, nginx/cloudflared/static edge, no private DB access.
- CT203: private controller/API/queue candidate, future live controller authority.
- CT204: private data/backups candidate on encrypted storage, future storage/backup support.
- PVESO: on-demand compute/model worker host only, offline unless needed.
- Laptop: not live authority; future optional worker only.

## Current proven assets

Already completed and verified:

- PVEW encrypted HDD was prepared with LUKS/ext4.
- Private mount exists at /srv/apc-private-data.
- Root-only helper exists at /root/apc-private-storage-unlock-mount.sh.
- CT204 private scaffold exists at /srv/apc-private-data/ct204.
- Controller SQLite backup exists on encrypted PVEW storage.
- Backup retrieval rehearsal passed.
- Live laptop DB was not overwritten.
- CT203 remains stopped.
- CT204 remains stopped.
- VM200 remains public/static only.

## Fast-lane plan

Fast-lane objective: get the website working from PVEW containers without keeping the laptop as runtime authority.

Recommended next sequence:

1. Read-only baseline PVEW runtime candidates:
   - VM200 status, nginx, cloudflared, local website health;
   - CT203 config/status;
   - CT204 config/status;
   - encrypted mount status;
   - Proxmox quorum context;
   - public route behavior.

2. Decide the minimum PVEW-contained runtime:
   - whether CT203 should host controller/API;
   - whether CT204 is only storage/backups initially;
   - whether VM200 proxies to CT203 or serves static fallback until CT203 is active.

3. Restore/copy controller runtime into CT203 only after explicit approval:
   - no laptop authority after cutover;
   - no authority switch until CT203 is verified;
   - rollback path required.

4. Cut website over to PVEW-contained services:
   - preserve construction/maintenance fallback until app health passes;
   - no public private-data exposure;
   - verify auth and app routes.

## Safety boundaries retained

Separate explicit approval is required for:

- starting CT203 or CT204;
- DB restore/import into CT203 or CT204;
- controller authority move;
- VM200 proxy/content mutation;
- Cloudflare/DNS/tunnel route mutation;
- service enable/start/restart;
- crypttab/fstab persistence;
- storage add/set;
- PVESO wake.

## Next recommended phase

Next phase should be read-only:

Phase 14J-JO - PVEW-contained website recovery baseline, read-only.

It should inspect VM200, CT203, CT204, encrypted storage, public route behavior, and repo state, without mutating anything.
