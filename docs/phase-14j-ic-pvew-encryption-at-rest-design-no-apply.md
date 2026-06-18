# Phase 14J-IC - PVEW encryption-at-rest design, no apply

Date: 2026-06-17

## Scope

Docs/smoke only. No storage mutation, key generation, data migration, CT/VM mutation, service mutation, route mutation, PVESO shutdown, or laptop authority removal.

Base checkpoint: Phase 14J-IB, commit 572ca52.

## Decision

PVEW may become the always-on host for future private controller/data candidates, but real user/platform data must not move there until encryption-at-rest is selected, applied under an explicit real-mutation boundary, and verified.

PVESO remains the on-demand model, worker, GPU, and heavy-compute host.

## Target boundary

Future direction:

- PVEW: website-edge plus private controller/data candidates.
- PVESO: workers and model runtime on demand.
- website-edge: public/static edge only.
- private data: encrypted-at-rest before authority migration.

## Website-edge isolation

website-edge must not contain user DB files, controller DB files, controller secrets, encryption keys, Proxmox management credentials, private data mounts, model secrets, worker secrets, or queue/controller authority.

If website-edge is exploited, the intended blast radius is public/static edge only, not user data or platform authority.

## Key rules

No key in ChatGPT, repo, Source files, APC_LAST_OUTPUT, terminal output, website-edge, public route config, Cloudflare Worker code, or tunnel config.

Manual unlock after boot is the safer first design unless a later no-apply risk review approves another unlock method.

## Backup rules

Backups containing user/platform data must be encrypted. Restore rehearsal must verify integrity without row-content output.

## Future prerequisites

Before real migration, define target CT IDs, storage volume, encryption method, unlock procedure, encrypted backup behavior, restore rehearsal, website-edge isolation checks, rollback path, exact mutation commands, and an explicit real-mutation approval boundary.

## Current recommendation

Continue no-apply PVEW target design and encryption implementation comparison. Do not create CTs, create encrypted volumes, generate keys, migrate data, stop PVESO, or alter public routes.
