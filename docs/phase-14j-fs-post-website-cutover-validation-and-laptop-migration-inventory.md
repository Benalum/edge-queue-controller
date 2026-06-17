# Phase 14J-FS - Post-website-cutover validation and laptop migration inventory

PHASE_14J_FS_POST_WEBSITE_CUTOVER_VALIDATION_AND_LAPTOP_MIGRATION_INVENTORY

## Status

Result: post_cutover_validation_passed_inventory_recorded_no_container_creation.

This phase records the successful read-only validation after the public/static website route was moved to `website-edge`, plus the first read-only inventory of what remains on the laptop before designing data/controller/worker containers.

This phase does not create containers, move controller/queue, mutate database/jobs, start workers, call CT101, call model endpoints, mutate Cloudflare routes, or mutate website-edge services.

## Starting checkpoint

Previous repo checkpoint:

- Phase: 14J-FP - website-edge production cutover preflight, no apply
- Commit: 2f7e0a9
- Tag: controller-phase-14j-fp-read-only-website-edge-production-cutover-preflight-2026-06-17
- Repo state at FS-R2 start: clean/current

## FS-R2 validation result

Phase 14J-FS-R2 completed with exit code 0.

Validated:

- repo clean/current at commit 2f7e0a9;
- Phase 14J-FP smoke regression passed;
- website-edge SSH/local loopback baseline was reachable;
- website-edge remote hostname validated as `website-edge`;
- website-edge OS validated as Ubuntu 26.04 LTS;
- website-edge local loopback `/` returned HTTP 200;
- website-edge local loopback `/app.js` returned HTTP 200;
- website-edge local loopback `/styles.css` returned HTTP 200;
- website-edge local loopback `/queued_chat_config.js` returned HTTP 200;
- local nginx active on website-edge;
- local cloudflared active and enabled on website-edge.

## Production/static route validation

The following production/public hostnames were validated against the website-edge loopback static asset baseline:

### alexhartel.com

- DNS A resolves: yes.
- DNS AAAA resolves: yes.
- HTTPS root returned HTTP 200.
- Root marker: wrapper_like.
- Root error marker: absent.
- `/app.js` returned HTTP 200 and matched website-edge loopback hash.
- `/styles.css` returned HTTP 200 and matched website-edge loopback hash.
- `/queued_chat_config.js` returned HTTP 200 and matched website-edge loopback hash.

### www.alexhartel.com

- DNS A resolves: yes.
- DNS AAAA resolves: yes.
- HTTPS root returned HTTP 200.
- Root marker: wrapper_like.
- Root error marker: absent.
- `/app.js` returned HTTP 200 and matched website-edge loopback hash.
- `/styles.css` returned HTTP 200 and matched website-edge loopback hash.
- `/queued_chat_config.js` returned HTTP 200 and matched website-edge loopback hash.

### website-edge-test.alexhartel.com

- DNS A resolves: no.
- DNS AAAA resolves: no.
- HTTPS root did not resolve.
- Interpretation: not a failure after production cutover because apex and www now point to website-edge.
- Diagnostic test hostname can be restored later if desired, but it is not required for the production static path if apex and www remain healthy.

## Static asset hashes

Observed website-edge loopback baseline and production public hashes:

- `/app.js`: `1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b`
- `/styles.css`: `c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19`
- `/queued_chat_config.js`: `5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b`

Result:

PHASE_14J_FS_STATIC_ROUTE_RESULT=apex_and_www_match_website_edge_loopback_baseline

## API route observation

`edge-api.alexhartel.com` did not resolve during FS-R2 read-only fingerprinting.

Interpretation:

- Do not assume edge-api is intentionally retired.
- Do not mutate edge-api as part of website-edge static route work.
- Controller/API route ownership needs a separate read-only design phase before any controller migration or route repair.
- If edge-api is required for live controller/API behavior, it should be handled in a separate phase with exact route target and rollback.

## Laptop service inventory

FS-R2 observed these relevant laptop system services:

- `cloudflared.service`: active/running.
- `docker.service`: active/running.
- `edge-queue-controller.service`: active/running.
- `edge-wrapper-ui.service`: active/running.
- `postgresql.service`: active/exited aggregate service.
- `postgresql@16-main.service`: active/running.
- `tailscaled.service`: active/running.

FS-R2 observed these relevant laptop user services:

- `project-pilot-bridge.service`: active/running.
- `gcr-ssh-agent.service`: active/running.

FS-R2 observed these project/power/control timers:

- `edge-queue-power-auto-tick.timer`.
- `edge-queue-power-idle-tick.timer`.
- `edge-queue-remediation-tick.timer`.

FS-R2 observed these relevant laptop ports by function:

- SSH service: port 22.
- PostgreSQL: port 5432.
- Edge queue/controller API: port 7070.
- Project Pilot Bridge: port 8765.
- Edge wrapper UI: port 8787.

Raw private/Tailscale IP details were intentionally not recorded in this document.

## Durable-state candidates

FS-R2 found these migration-relevant durable-state candidates:

- `edge_queue.sqlite3`, approximately 42 MB.
- PostgreSQL 16 running on the laptop.
- `docs/laptop-postgres-backup-restore.md`.
- `ops/db/backup-laptop-postgres.sh`.
- `ops/db/laptop-app-schema-v1.sql`.
- `ops/db/laptop-app-schema-v2-chat-source-job-id.sql`.
- `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`.
- `ops/db/default-off-worker-registry-lane-metadata.sql`.

Interpretation:

- The next container design must determine whether PostgreSQL, SQLite, or both are authoritative for current controller/queue/platform data.
- Do not move controller/queue until durable state ownership, backup, restore, and rollback are proven.

## Migration dependency map

### website-edge VM 200

Current role:

- public/static website edge;
- nginx static runtime on loopback `18080`;
- Cloudflare tunnel serving `alexhartel.com` and `www.alexhartel.com`.

Keep out of website-edge:

- controller/queue;
- database authority;
- worker process;
- CT101/model control;
- Proxmox management;
- public-user infrastructure controls.

### future data container or VM

Candidate role:

- durable data ownership;
- PostgreSQL if retained;
- SQLite state if retained;
- backups and restore scripts;
- migrations and rollback artifacts.

Must be designed before controller/queue migration.

### future controller/queue container

Candidate role:

- `edge-queue-controller.service`;
- controller API currently associated with port 7070;
- scheduler/timer logic;
- queue authority;
- auth/session/controller-owned APIs if currently laptop-owned;
- private API route target after a separate route plan.

Must not be public control-plane exposure.

### future worker container

Candidate role:

- queue worker process;
- lane worker services later;
- model dispatch client only.

Must not start until separately approved. No CT101 or model endpoint calls in this phase.

### laptop target role

Keep temporarily:

- repo development;
- docs/smokes/commit/tag/push;
- Project Pilot Bridge;
- emergency admin SSH.

Remove later after migration:

- public website serving dependency;
- controller/queue API dependency;
- wrapper UI service dependency;
- laptop Cloudflare tunnel dependency;
- PostgreSQL production dependency;
- durable queue/database state dependency.

## Proposed next phase

Phase 14J-FT should be a read-only data-container design and data authority inspection.

Required questions for FT:

1. Is PostgreSQL currently authoritative for user/account/profile/credits/auth data?
2. Is `edge_queue.sqlite3` currently authoritative for queue/job/worker/router state?
3. Which services read/write PostgreSQL?
4. Which services read/write `edge_queue.sqlite3`?
5. What exact backup/restore proof is required before creating a data container?
6. Should the first data target be a container or VM?
7. What rollback keeps the laptop authoritative until the data target is proven?

## Still not performed

- no container creation;
- no controller/queue migration;
- no data migration;
- no worker start;
- no CT101 call;
- no model/Ollama endpoint call;
- no production DB/job mutation;
- no Proxmox public exposure;
- no nginx config mutation;
- no Docker install;
- no Node/npm install;
- no Tailscale ACL/grants/tag mutation;
- no Tailscale SSH mode enablement;
- no subnet route;
- no exit node;
- no Cloudflare API token use;
- no token printing;
- no raw private IP recording;
- no Phase 14J-AG apply wrapper rerun.

## Phase result

PHASE_14J_FS_RESULT=post_cutover_validation_passed_laptop_migration_inventory_recorded

NEXT_SAFE_PHASE=phase_14j_ft_read_only_data_container_design_and_data_authority_inspection
