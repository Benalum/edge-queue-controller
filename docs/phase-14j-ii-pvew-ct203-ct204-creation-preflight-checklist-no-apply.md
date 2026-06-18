# Phase 14J-II - PVEW CT203/CT204 Creation Preflight Checklist, No Apply

## Scope

This phase records the preflight checklist required before any future CT203/CT204 creation boundary.

This phase does not approve or perform CT creation, CT start, CT clone, storage creation, formatting, mounting, encryption setup, key generation, DB dump/copy/import/migration, service activation, onboot mutation, PVESO power action, public route mutation, Cloudflare/DNS/tunnel mutation, CT101 call, model call, worker start, or production DB/job mutation.

## Current checkpoint

- Previous checkpoint: Phase 14J-IH at commit `5bd30a7`.
- CT203 and CT204 are still not created by this phase.
- Laptop controller remains live controller/queue authority.
- Laptop-local `edge_queue.sqlite3` remains live primary controller platform data authority.
- VM200 `website-edge` remains public/static edge only.
- PVESO remains on-demand compute/model/worker/GPU host.

## Required preflight before future creation

Before any CT203/CT204 creation mutation, verify:

1. repo head, origin, tag, and clean state;
2. laptop DB quick_check is ok;
3. laptop controller listeners are still present;
4. PVEW is reachable as Proxmox host;
5. VM200 `website-edge` is running and remains public/static edge only;
6. CT203 is unused;
7. CT204 is unused;
8. chosen PVEW storage target has enough capacity;
9. no encrypted private data volume is assumed yet;
10. no user/platform data is copied, dumped, imported, or migrated;
11. no encryption key is generated, printed, stored, or installed;
12. no service is enabled as authority;
13. no onboot/autostart mutation occurs unless explicitly included;
14. no public route, DNS, Cloudflare, or tunnel mutation occurs;
15. rollback/stop condition is defined before command execution.

## Stop conditions for future creation boundary

Stop immediately if:

- CT203 or CT204 already exists unexpectedly;
- PVEW storage target is unavailable or ambiguous;
- laptop authority is unhealthy;
- VM200 posture suggests private data or controller authority is present;
- any command would print secrets, tokens, keys, or raw private addressing;
- any command would migrate/copy/dump/import user or platform data;
- any command would alter public routes or tunnel configuration;
- any command would start CT101, call a model endpoint, or start a worker.

## Future boundary requirement

The next real mutation must be separately approved and must explicitly state that CT203/CT204 creation is allowed on PVEW as private, non-authoritative candidates only.

## Result

`NO_APPLY_PREFLIGHT_ONLY_CT203_CT204_NOT_CREATED`
