# Phase 14J-IH - PVEW CT203/CT204 Resource Specification, No Apply

## Scope

This phase records the intended private candidate resource shape for future PVEW CT203 and CT204.

This is a no-apply documentation and smoke phase only.

No CT creation, CT start, CT clone, storage creation, storage formatting, storage mounting, encryption setup, key generation, DB dump, DB copy, DB import, DB migration, service activation, onboot mutation, PVESO power action, public route mutation, Cloudflare/DNS/tunnel mutation, CT101 call, model call, worker start, or production DB/job mutation is approved or performed.

## Current authority remains unchanged

- Laptop controller remains the live controller/queue authority.
- Laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority.
- VM200 `website-edge` remains public/static edge only.
- CT203 and CT204 are still planned private candidates only.
- PVESO remains on-demand compute/model/worker/GPU host.

## Candidate resource specification

### CT203 `edge-controller-pvew`

Role:

- private controller candidate only;
- non-authoritative until later explicit migration/cutover;
- no public route;
- no direct model/worker authority;
- no user/platform data import during creation boundary.

Initial resource target:

- Proxmox node: PVEW;
- CT ID: 203;
- hostname: `edge-controller-pvew`;
- CPU: 2 vCPU;
- memory: 2048 MiB;
- swap: 512 MiB;
- root disk target: PVEW local-lvm or other approved non-public storage;
- network: private LAN/Tailscale reachable only;
- autostart/onboot: remain off unless later explicitly approved;
- service state after creation: no controller service enabled as authority.

### CT204 `edge-data-pvew`

Role:

- private encrypted data/backups candidate only;
- non-authoritative until later explicit encrypted-storage and data-authority boundaries;
- no public route;
- no keys in website-edge, repo, Source, ChatGPT, or APC_LAST_OUTPUT.

Initial resource target:

- Proxmox node: PVEW;
- CT ID: 204;
- hostname: `edge-data-pvew`;
- CPU: 1 vCPU;
- memory: 1024 MiB;
- swap: 512 MiB;
- root disk target: PVEW local-lvm or other approved non-public storage;
- private data mount: not created in this phase;
- encrypted storage: not created in this phase;
- autostart/onboot: remain off unless later explicitly approved.

## Required checks before any future creation boundary

Before CT203/CT204 creation, verify:

1. repo head/tag/clean state;
2. laptop authority still active;
3. VM200 remains isolated as public/static edge only;
4. CT203 and CT204 still unused;
5. PVEW storage target selected and has enough capacity;
6. no encryption key will be printed or stored in output;
7. no data will be copied, dumped, imported, or migrated;
8. no public route or tunnel will be changed;
9. exact rollback/stop condition is defined.

## Result

`NO_APPLY_RESOURCE_SPEC_ONLY_CT203_CT204_NOT_CREATED`
