# Phase 14J-HA - Read-only current authority and edge posture inventory

Date: 2026-06-17  
Type: read-only baseline / docs-smoke record  
Previous checkpoint: Phase 14J-GZ at commit `ccfad10`

## Purpose

Record the new-chat read-only baseline completed after the Phase 14J-GZ Source refresh.

This phase confirms current live authority, private candidate boundaries, and public/static website-edge posture before any future controller cutover or apply consideration.

## Mutation boundary

This phase records evidence only.

It does not perform:

- CT202 authority cutover;
- CT202 data migration or import;
- `systemctl start`;
- `systemctl enable`;
- CT202 onboot/autostart mutation;
- VM start, stop, or reboot;
- Cloudflare, DNS, or tunnel mutation;
- public route mutation;
- laptop controller stop or pause;
- live laptop DB mutation;
- CT101 call;
- model/Ollama endpoint call;
- worker start;
- production DB/job mutation;
- secret generation, printing, or installation;
- destructive GitHub branch or repository deletion.

## Repo/source baseline

The baseline verified:

- repo HEAD was `ccfad10`;
- local `origin/main` was `ccfad10`;
- working tree was clean;
- remote `main` and the Phase 14J-GZ tag pointed to `ccfad10`;
- Phase 14J-GZ smoke existed and passed;
- the old Phase 14J-AG apply wrapper was not run.

## Laptop live authority baseline

The laptop remains the live controller and queue authority.

Observed read-only laptop posture:

- controller-like runtime present on laptop;
- laptop loopback port `7070` open for the controller;
- laptop loopback port `8787` open for the wrapper UI;
- laptop loopback port `8765` open for Project Pilot Bridge;
- laptop-local `edge_queue.sqlite3` quick_check was `ok`;
- laptop application table count was `39`;
- safe metadata counts observed:
  - `jobs`: `22`;
  - `workers`: `2`;
  - `user_sessions`: `233`;
  - `router_logs`: `0`.

The laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority.

## Public/static website response baseline

Public website paths responded read-only with HTTP `200`:

- `/`;
- `/chat`;
- `/profile`;
- `/system`.

No public route, Cloudflare, DNS, or tunnel mutation was performed.

## CT201 private data candidate baseline

CT201 `edge-data` posture:

- status: stopped;
- hostname: `edge-data`;
- onboot: `0`.

CT201 remains private and non-authoritative.

## CT202 private controller candidate baseline

CT202 owner node was found as `pveso`.

CT202 `edge-controller` posture:

- status: running container;
- hostname: `edge-controller`;
- onboot: `0`;
- app/current path exists;
- venv path exists;
- local SQLite candidate DB exists;
- `edge-queue-controller.service` is `disabled`;
- `edge-queue-controller.service` is `inactive`;
- no checked controller/smoke listener active on loopback ports `7070`, `17070`, `17071`, or `17072`;
- CT202 SQLite candidate DB quick_check was `ok`;
- CT202 application table count was `25`;
- safe metadata counts observed:
  - `jobs`: `0`;
  - `workers`: `0`;
  - `user_sessions`: `0`;
  - `router_logs`: `0`.

CT202 remains a private controller candidate only and is not authoritative.

## VM 200 website-edge baseline

VM 200 owner node was found as `pvew`.

VM 200 `website-edge` posture:

- status: running;
- name: `website-edge`;
- qemu guest agent enabled;
- qemu guest agent responded;
- cores: `2`;
- memory: `2048`;
- network bridge: `vmbr0`;
- onboot: `0`.

VM 200 remains the public/static website edge role only. It is not controller, queue, worker, model, or DB authority.

## Current authority conclusion

Current live authority remains unchanged:

- laptop controller remains live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains live primary controller platform data authority;
- VM 200 is public/static website edge only;
- CT201 is private data/backups/future data-service candidate only;
- CT202 is private future controller candidate only.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

## Remaining blockers before any future apply

The following remain unresolved before any CT202 controller authority cutover can be considered:

1. data authority path must be selected and approved;
2. persistent secret/public API key policy must be applied or explicitly ruled unnecessary for the scoped rehearsal;
3. runtime rehearsal must be explicitly approved before any `systemctl start`;
4. public route target and rollback target must be approved before any route mutation;
5. laptop fallback and split-brain prevention must be proven current;
6. CT101/model/worker runtime remains out of scope unless separately approved.

## Recommended next safe paths

After this checkpoint, safe next paths are:

- continue no-apply planning;
- prepare a read-only data-authority comparison plan;
- prepare a temporary CT202 runtime rehearsal approval phrase and command plan, without running it;
- prepare a rollback drill plan;
- perform a Source refresh only at a stable handoff or before explicit runtime/cutover approval.
