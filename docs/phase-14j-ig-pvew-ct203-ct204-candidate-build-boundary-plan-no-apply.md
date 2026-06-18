# Phase 14J-IG - PVEW CT203/CT204 Candidate Build Boundary Plan, No Apply

## Scope

This phase records the next real-mutation boundary design for future PVEW private candidates.

No creation, start, clone, storage mutation, encryption setup, key generation, data movement, service activation, onboot mutation, PVESO power action, public route mutation, Cloudflare/DNS/tunnel mutation, CT101 call, model call, worker start, or production DB/job mutation is approved or performed by this phase.

## Baseline evidence

Read-only baseline completed after Phase 14J-IF:

- repo/head/origin/tag/clean state verified at `b4bc6d5`;
- laptop-local `edge_queue.sqlite3` quick_check passed and remains live data authority;
- laptop controller listeners on `7070`, `8787`, and `8765` were present;
- PVEW was reachable through Tailscale;
- PVEW VM200 `website-edge` was running;
- PVEW CT203 and CT204 were unused;
- PVEW `cryptsetup` was available, but encryption-at-rest was not yet created or proven;
- PVESO CT101 and CT201 were stopped with onboot `0`;
- PVESO CT202 was running only as old non-authoritative candidate with service disabled/inactive and checked listeners at `0`.

## Future target roles

- CT203 `edge-controller-pvew`: private controller candidate only.
- CT204 `edge-data-pvew`: private encrypted data/backups candidate only.
- VM200 `website-edge`: public/static edge only; no private data, keys, controller authority, or Proxmox credentials.
- Laptop: live controller/queue/DB authority until a later explicit migration/cutover boundary.
- PVESO: on-demand CT101/model/worker/GPU host until a later explicit power/runtime boundary.

## Required future real-mutation boundary

Before CT203 or CT204 creation, the operator must explicitly approve a separate real-mutation boundary that states:

1. exact CT IDs and names;
2. target Proxmox node is PVEW;
3. no authority migration;
4. no user/platform data copy/import/dump;
5. no encryption key output;
6. no service activation beyond approved package/container creation steps;
7. no onboot/autostart mutation unless explicitly included;
8. no public route or tunnel mutation;
9. rollback/cleanup stop condition;
10. post-creation private posture verification.

## Preferred ordering after this no-apply phase

1. Draft exact CT203/CT204 create plan under explicit mutation boundary.
2. Create CT203/CT204 as empty/private non-authoritative candidates only.
3. Verify CT203/CT204 private posture.
4. Plan encrypted storage separately.
5. Create encrypted private data storage under a separate explicit boundary.
6. Only later consider data migration/import and PVESO shutdown under separate boundaries.

## Result

`NO_APPLY_BOUNDARY_PLAN_ONLY_CT203_CT204_NOT_CREATED`
