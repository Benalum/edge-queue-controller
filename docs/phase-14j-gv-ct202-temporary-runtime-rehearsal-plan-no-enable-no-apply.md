# Phase 14J-GV - CT202 Temporary Runtime Rehearsal Plan - NO ENABLE / NO APPLY

Date: 2026-06-17  
Phase: 14J-GV  
Scope: CT202 temporary runtime rehearsal plan only, no enable, no apply  
Previous checkpoint: Phase 14J-GU - CT202 persistent secret/public API key policy no apply  
Previous commit: 5d787e5  
Previous tag: controller-phase-14j-gu-ct202-persistent-secret-public-api-key-policy-no-apply-2026-06-17

## Result

Phase 14J-GV documents a future CT202 temporary runtime rehearsal plan.

This phase does **not** start CT202 controller runtime.

This phase does **not** enable CT202 service.

This phase does **not** mutate CT202, systemd, Proxmox onboot/autostart, Cloudflare, public routes, laptop controller, or any database.

## Current unchanged authority boundary

Live authority remains unchanged:

- laptop controller remains the live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority;
- CT202 remains a private controller candidate only;
- CT202 is not authoritative;
- CT202 service remains disabled/inactive;
- CT202 onboot/autostart remains off;
- no CT202 controller listener/runtime should be active;
- CT201 remains private data/backups/future data-service candidate only;
- VM 200 `website-edge` remains public/static website edge only.

## Purpose of a future rehearsal

A future rehearsal should prove that CT202 can temporarily start, answer private loopback runtime checks, then return to disabled/inactive with no persistent activation.

A future rehearsal must remain separate from:

- persistent service enablement;
- Proxmox onboot/autostart;
- public route mutation;
- data migration/import;
- laptop controller shutdown;
- CT202 authority promotion.

## Future rehearsal sequence

This is a plan only.

A later apply phase, if explicitly approved, should use this shape:

1. Preflight repo and Source checkpoint.
2. Verify CT202 is running for inspection.
3. Verify CT202 onboot/autostart is off.
4. Verify `edge-queue-controller.service` is loaded, disabled, and inactive.
5. Verify no CT202 controller listener exists on guarded ports.
6. Verify no Uvicorn controller process exists.
7. Verify CT202 SQLite quick_check returns `ok`.
8. Verify CT202 key live tables remain expected for candidate state.
9. Start the service temporarily only for private loopback smoke.
10. Smoke only private loopback runtime endpoints.
11. Stop the service.
12. Verify service returns inactive.
13. Verify service remains disabled.
14. Verify CT202 onboot/autostart remains off.
15. Verify no guarded-port listener/runtime remains.
16. Record results and do not leave runtime active unless separately approved.

## Future private smoke targets

Future rehearsal smokes may include private loopback-only checks such as:

- `/openapi.json`;
- controller health/status route if already present;
- system/queue read-only status route if already present;
- auth route only if a temporary in-process or safely injected non-printed key policy is explicitly approved.

No public hostname should be used in this rehearsal.

No public route should point to CT202.

No CT101, model, worker, or production job endpoint should be called.

## Runtime secret boundary

Phase 14J-GU recorded that persistent secret/public API key policy exists only as a no-apply planning artifact.

A future rehearsal must not print, commit, paste, or store secret material.

If a future rehearsal requires a key, it must use a separately approved safe mechanism:

- temporary in-process value that is never printed; or
- root-owned `0600` runtime environment file created in a separately approved apply phase; or
- another approved mechanism that never prints or stores secret material in unsafe locations.

This phase creates no secret.

This phase creates no environment file.

This phase mutates no systemd unit.

## Stop and rollback requirements for future rehearsal

A future rehearsal must include stop and cleanup checks:

- service inactive after rehearsal;
- service disabled after rehearsal;
- no controller listener on guarded ports;
- no Uvicorn controller process;
- CT202 onboot/autostart still off;
- no public route changed;
- laptop controller still live authority;
- laptop DB still live authority;
- no DB migration/import happened.

If any private runtime check fails, the future apply phase should stop the CT202 service, verify disabled/inactive state, and stop.

## Explicitly not performed in this phase

- no CT202 authority cutover;
- no CT202 temporary runtime start;
- no CT202 persistent runtime activation;
- no CT202 data migration/import;
- no laptop DB export/import;
- no SQLite copy;
- no secret generation;
- no secret printing;
- no secret file creation;
- no environment file creation;
- no systemd unit mutation;
- no `systemctl start`;
- no `systemctl enable`;
- no `systemctl daemon-reload`;
- no CT202 onboot/autostart mutation;
- no public route mutation;
- no Cloudflare mutation;
- no laptop controller stop;
- no live laptop DB mutation;
- no CT101 call;
- no model/Ollama endpoint call;
- no worker start;
- no production DB/job mutation;
- no rerun of the Phase 14J-AG apply wrapper;
- no destructive GitHub branch/repository deletion.

## Required next no-apply phase

Next safe phase: Phase 14J-GW - CT202 data authority preflight plan, no import, no apply.

Reason:

- runtime rehearsal plan is now documented;
- data authority still needs a read-only preflight plan before any import/migration decision;
- public route and rollback planning should wait until runtime and data authority boundaries are clearer.

## Phase 14J-GV conclusion

CT202 temporary runtime rehearsal is planned but not executed.

No runtime was started, enabled, or left active by this phase.

Next safe phase: Phase 14J-GW - CT202 data authority preflight plan, no import, no apply.
