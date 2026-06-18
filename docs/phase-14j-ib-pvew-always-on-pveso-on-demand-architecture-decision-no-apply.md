# Phase 14J-IB - PVEW always-on and PVESO on-demand architecture decision, no apply

Date: 2026-06-17

## Scope

This phase records a no-apply architecture decision based on the read-only PVEW/PVESO inventories.

Mutation scope for this phase:

- docs/smoke only;
- no CT/VM create, delete, start, or stop;
- no host shutdown, reboot, or wake command;
- no data migration/import/copy/dump;
- no SQLite `.dump` or row-content output;
- no `systemctl start`, `stop`, `restart`, `reload`, `enable`, or `disable`;
- no CT202 restore, rebuild, or schema apply;
- no CT202 onboot/autostart mutation;
- no Cloudflare, DNS, or tunnel mutation;
- no laptop controller stop/pause;
- no live DB mutation;
- no CT101, model/Ollama, or worker call;
- no destructive GitHub branch/repository deletion.

This phase does not approve any real migration or power mutation.

## Base checkpoint

Base checkpoint for this phase:

- Phase: `14J-IA`
- Commit: `0ff0b32`
- Tag: `controller-phase-14j-ia-real-mutation-boundary-preflight-checklist-no-apply-2026-06-17`
- IA result: `PASS_DOCS_SMOKE_ONLY_REAL_MUTATION_BOUNDARY_PREFLIGHT_CHECKLIST_NO_APPLY`

## Read-only PVESO evidence

The PVESO shutdown-readiness inventory showed:

- PVESO hostname: `pveso`;
- CT101 `llms`: present, stopped, onboot `0`;
- CT201 `edge-data`: present, stopped, onboot `0`;
- CT202 `edge-controller`: present, running, onboot `0`;
- CT202 service enabled state: `disabled`;
- CT202 service active state: `inactive`;
- CT202 checked listener count on `7070`: `0`;
- CT202 checked listener count on `8787`: `0`;
- CT202 checked listener count on `8765`: `0`;
- CT202 DB path present;
- CT202 DB size: `262144`;
- CT202 DB quick_check: `ok`;
- VM200 `website-edge`: not present on PVESO;
- Wake-on-LAN hint existed on the inspected interface.

Conclusion: PVESO is currently a good candidate for an on-demand model/worker/compute host, not an always-on public/control/data host.

## Read-only PVEW evidence

The PVEW inventory showed:

- PVEW hostname: `pvew`;
- CPU model: `Intel(R) Core(TM) i3-10100 CPU @ 3.60GHz`;
- CPU count: `8`;
- memory total: `7787 MiB`;
- memory available: `4246 MiB`;
- load average at inventory time: `0.15 0.08 0.02`;
- VM200 `website-edge`: present and running;
- VM200 cores: `2`;
- VM200 memory: `2048 MB`;
- VM200 disk: `20 GB`;
- VM200 onboot: `0`;
- CT101, CT201, CT202, CT203, and CT204 were not present on PVEW;
- `local` storage was active with about `26 GB` available;
- `local-lvm` storage was active with about `39 GB` available;
- `data-2tb` storage was disabled;
- `cryptsetup` was available;
- current block/storage evidence showed LVM/ext4 indicators but did not prove encryption-at-rest for user data.

Conclusion: PVEW is suitable for always-on lightweight platform edge/control/data candidates, subject to storage sizing and encryption-at-rest design.

## Architecture decision

Adopt the following target architecture as the no-apply direction:

```text
Always on: PVEW
  - VM 200 website-edge
      - public/static website edge only
      - nginx/static wrapper and Cloudflare tunnel edge
      - no user DB
      - no queue/controller authority
      - no model/worker authority
      - no Proxmox management role
      - no controller secrets or user-data storage

  - Future private controller candidate
      - private CT only
      - not inside website-edge VM
      - controller/queue API candidate
      - no public authority until later explicit cutover

  - Future private data/backups candidate
      - private CT or dedicated encrypted storage path
      - not inside website-edge VM
      - encrypted-at-rest user/platform data before real migration

On demand: PVESO
  - CT101/model runtime/workers
  - GPU/heavy AI jobs
  - worker/model compute capacity
  - powered on only when needed after wake/preflight
Role boundary

The website VM may share the same physical host as private controller/data candidates, but it must not share authority or data.

Hard separation requirements:

website-edge must not contain user DB files;
website-edge must not contain controller secrets;
website-edge must not contain Proxmox management credentials;
website-edge must not mount private controller/data storage;
website-edge must remain public/static edge only;
private controller/data roles must live in separate private CTs or equivalent private isolation;
public route changes require a later explicit boundary.
Encryption-at-rest decision

User/platform data must be encrypted at rest before a real migration to PVEW data authority.

This phase does not choose the exact encryption implementation.

Acceptable future design paths may include:

host-level encrypted storage prepared before placing user data;
a dedicated encrypted data volume attached only to the private data/controller role;
application-level encryption for sensitive user fields plus encrypted filesystem/storage;
backup encryption with tested restore behavior.

Before real data migration, a future no-apply phase must define:

encryption boundary;
key handling rule;
boot/unlock behavior;
backup encryption behavior;
restore test behavior;
what must never be stored in website-edge.
Capacity decision

PVEW appears appropriate for lightweight always-on roles:

public/static website edge;
private controller candidate;
private data/backups candidate;
low-volume queue/control-plane duties.

PVEW is not the preferred host for:

model inference;
Ollama/model endpoints;
GPU workloads;
worker-heavy processing;
large-scale user data growth without added storage planning.

PVESO remains the preferred host for on-demand compute/model/worker capacity.

Migration posture

No authority moves in this phase.

Current live authority remains:

laptop controller as live controller/queue authority;
laptop-local edge_queue.sqlite3 as live primary controller platform data authority.

Future migration should proceed as:

no-apply PVEW target design;
no-apply encryption-at-rest design;
no-apply backup/restore design;
create private PVEW controller/data candidates under explicit mutation boundary;
rehearse privately;
select data authority explicitly;
cut over only under a later explicit real-mutation and public-route boundary.
Current recommendation

Continue with no-apply PVEW target design and encryption-at-rest planning.

Do not migrate user data, stop PVESO, create CTs, copy DB files, or alter public routes until a separate explicit real-mutation boundary is opened.
