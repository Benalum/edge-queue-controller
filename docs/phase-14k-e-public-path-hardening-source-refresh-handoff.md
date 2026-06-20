# Phase 14K-E — Public Path Hardening Source Refresh Handoff

Date: 2026-06-19  
Base checkpoint: Phase 14K-D / HEAD `44e1064`  
Mutation scope: repo docs/smoke only

## Purpose

Record the Stage 14K public-path hardening milestone and prepare the project for either a new chat handoff or Stage 15 feature work.

## Latest verified repository checkpoint

Repository: `~/Desktop/edge-queue-controller`

- HEAD/origin/main: `44e1064`
- Latest tag: `controller-phase-14k-d-public-path-hardening-validation-2026-06-19`
- Latest completed phase: Phase 14K-D public path hardening validation
- Repo state: clean after commit/tag/push

## Completed Stage 14K outcome

Stage 14K public-path hardening is complete through validation.

Completed:

- 14K-A inspected VM200 nginx upstreams, CT203 address behavior, route compatibility, app hash, and safety invariants.
- 14K-B chose static CT203 addressing as the durable upstream strategy.
- 14K-C applied CT203 static LXC `net0` and VM200 `/api/system/status` compatibility under explicit approval.
- 14K-D validated local and public route behavior and checkpointed the result.

## Current platform authority

- PVEW is the always-on platform host.
- VM200 `website-edge` is the public/static edge host.
- CT203 `edge-controller-pvew` is controller/API/status/queue authority.
- CT204 `edge-data-pvew` is backup-data-only, stopped, and non-authority.
- Laptop is operator workstation / PPB caller only.
- PVESO remains outside public website authority and must not be mutated without explicit approval.

## Current public route state

Validated after 14K-D:

- Public `/` returns HTTP 200.
- Public `/system/status` returns HTTP 200.
- Public `/api/system/status` returns HTTP 200.
- Public `/api/me` returns HTTP 401 unauthenticated, expected.

## Current VM200 route state

Validated after 14K-D:

- VM200 nginx is active.
- VM200 cloudflared is active.
- VM200 nginx config test passes.
- Active wrapper route is `127.0.0.1:18080`.
- VM200 local `127.0.0.1:18080/healthz` returns HTTP 200.
- VM200 local `127.0.0.1:18080/system/status` returns HTTP 200.
- VM200 local `127.0.0.1:18080/api/system/status` returns HTTP 200.
- VM200 local `127.0.0.1:18080/api/me` returns HTTP 401.

## Current CT203 route and network state

Validated after 14K-D:

- CT203 is running.
- CT203 `net0` is static and includes a gateway.
- CT203 is no longer configured as DHCP in Proxmox/LXC config.
- CT203 direct `/system/status` returns HTTP 200.
- CT203 direct `/api/system/status` returns HTTP 404.
- `/api/system/status` compatibility is intentionally provided by VM200 nginx mapping to CT203 `/system/status`.

## Safety invariants

Validated after 14K-D:

- PVEW remains quorate.
- Expected votes: 1.
- Total votes: 1.
- CT204 remains stopped.
- CT204 remains onboot=0.
- Private storage `/srv/apc-private-data` is not mounted.
- `/dev/mapper/apc_private_data` is absent.
- Workers/models/scheduler remain parked.
- No live model endpoint calls were made.
- No DB migration/import/restore was performed.
- No PVESO mutation was performed.
- No Cloudflare/DNS/tunnel config mutation was performed.
- No Proxmox cluster/corosync mutation was performed.

## Important 14K-C note

During the approved 14K-C apply, Proxmox reported `Address already assigned` while applying CT203 static net0 because the running container already held the same current address on `eth0`. The config mutation still succeeded, CT203 remained reachable, and 14K-D validated that CT203 config is static with gateway.

No CT203 restart was performed.

## Remaining blockers before feature work

No public-path hardening blocker remains.

Still gated by explicit approval:

- worker/model/scheduler activation
- live model endpoint calls
- DB migration/import/restore
- CT204 start or authority change
- private storage unlock/mount
- PVESO mutation
- Cloudflare/DNS/tunnel mutation
- CT/VM restart
- service restart/reload

## Recommended next stage

Begin Stage 15: Controller/queue/Decision Maker integration.

Recommended first Stage 15 phase:

- read-only inventory of CT203 API routes, queue schema, SQLite DB tables, service status, scheduler/worker flags, and current frontend/API paths
- no DB mutation
- no worker activation
- no model calls
- no scheduler activation
- no service restart/reload

After inventory, define the Decision Maker boundary and queue contract before any Ollama/model worker activation.

## Chat title suggestion

AI Platform Control — Phase 14K Public Path Hardened + CT203 Static Upstream

## New chat handoff prompt

Continue AI Platform Control from the Phase 14K-E Public Path Hardening Source Refresh Handoff.

Use the uploaded Source files as project authority unless I paste newer terminal output.

Current verified repo checkpoint:

- Repo: `~/Desktop/edge-queue-controller`
- HEAD/origin/main: `44e1064`
- Latest validated tag: `controller-phase-14k-d-public-path-hardening-validation-2026-06-19`
- Repo state: clean after commit/tag/push

Current platform state:

- PVEW is the always-on platform host.
- PVEW is quorate, expected votes 1, total votes 1.
- VM200 `website-edge` is running and onboot=1.
- CT203 `edge-controller-pvew` is running and onboot=1.
- CT203 `net0` is static with gateway, no longer DHCP.
- VM200 nginx/cloudflared public path is healthy.
- Public `/` is HTTP 200.
- Public `/system/status` is HTTP 200.
- Public `/api/system/status` is HTTP 200.
- Public `/api/me` is HTTP 401 unauthenticated, expected.
- VM200 local wrapper `127.0.0.1:18080/api/system/status` is HTTP 200.
- CT203 direct `/system/status` is HTTP 200.
- CT203 direct `/api/system/status` is HTTP 404; compatibility is intentionally handled by VM200 nginx.
- CT204 is stopped and onboot=0; it is backup-data-only and not authority.
- Private storage `/srv/apc-private-data` remains locked/unmounted and `/dev/mapper/apc_private_data` is absent.
- Laptop is not live public/controller authority.
- PVESO is outside the public website authority path and must not be mutated without explicit approval.

Important completed phases:

- 14J-NP validated PVEW reboot/autostart at `60b65c4`.
- 14K-B chose static CT203 upstream strategy at `0439a3c`.
- 14K-C applied CT203 static network + VM200 `/api/system/status` compatibility under explicit approval.
- 14K-D validated public/local routes and checkpointed at `44e1064`.

Standing rules:

- Use `# PPB_RUN` for operational bash blocks.
- Do not use PPB for GitHub branch/repository deletion or destructive repository removal actions.
- Safe read-only/no-apply/docs phases can proceed without asking for approval.
- Real mutations require explicit approval: PVEW reboot/shutdown, PVESO mutation, CT/VM start/stop/restart/config changes, service reload/restart, nginx/cloudflared config changes, Cloudflare/DNS/tunnel, DB migration/import/restore, private storage unlock/mount, CT204 start/authority change, worker/model/scheduler activation, live model endpoint calls, Proxmox cluster/corosync mutation.
- Keep private storage locked, CT204 stopped, workers/models/scheduler off, and PVESO untouched unless explicitly approved.
- Avoid long fragile code blocks and avoid `grep -q` directly after long pipelines under `pipefail`; capture output first.

Next recommended phase:

Start Stage 15 with a compact read-only/no-apply CT203 controller/queue/Decision Maker inventory. Focus on API routes, queue tables/schema, scheduler and worker activation flags, service/env boundaries without printing secrets, frontend paths that will call the queue, and model/Ollama integration blockers. Do not activate workers, scheduler, or live model calls yet.
