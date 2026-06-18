# Phase 14J-HV - CT202 candidate rebuild apply design, no apply

Date: 2026-06-17  
Type: candidate rebuild apply design / docs-smoke record  
Previous checkpoint: Phase 14J-HU at commit `a47821d`  
Approval phrase used: `APPROVE_PHASE_14J_HV_CT202_CANDIDATE_REBUILD_APPLY_DESIGN_NO_APPLY`

## Purpose

Define the future CT202 candidate-only rebuild mutation boundary before any actual apply work exists.

This phase is docs/smoke only.

This phase does not create an apply script.

This phase does not execute restore, rebuild, schema apply, data import, service activation, route mutation, or cutover.

## HU gate input

Phase 14J-HU recorded:

`PASS_FOR_NEXT_NO_APPLY_PLANNING_ONLY`

That allows this no-apply design phase only.

It does not approve any CT202 mutation.

## Candidate rebuild design posture

The future candidate rebuild, if later approved, should be:

- CT202-private only;
- candidate-only;
- schema-first;
- no live authority promotion;
- no public route mutation;
- no service activation;
- no data authority selection;
- no laptop DB mutation;
- no CT101/model/Ollama/worker call.

The future candidate rebuild must not make CT202 public authority.

The future candidate rebuild must keep CT202 service disabled/inactive.

The future candidate rebuild must keep CT202 onboot `0`.

The future candidate rebuild must keep the CT202 cutover readiness gate CLOSED.

## Future mutation boundary design

A later candidate rebuild apply phase, if explicitly approved, may only mutate CT202 private candidate state inside CT202.

Allowed future mutation target:

`/srv/edge-controller/data/edge_queue.sqlite3`

Allowed future mutation type:

- preserve current CT202 candidate DB first;
- create or replace CT202 candidate DB with a schema-compatible candidate DB;
- verify schema/table posture after creation;
- keep CT202 private and inactive.

Not allowed in that future candidate rebuild apply:

- restore live authority;
- select data authority;
- import laptop live data;
- dump laptop DB;
- print row content;
- mutate laptop DB;
- mutate public routes;
- start services;
- enable services;
- change CT202 onboot;
- call CT101;
- call model/Ollama endpoints;
- start workers.

## Required pre-apply guards for any future candidate rebuild

A future mutating candidate rebuild phase must require:

1. explicit future candidate-rebuild approval phrase;
2. repo HEAD at expected checkpoint;
3. clean working tree;
4. HM/HN backup artifacts verified;
5. HT private rehearsal passed;
6. HU risk gate recorded as `PASS_FOR_NEXT_NO_APPLY_PLANNING_ONLY`;
7. CT202 status `running`;
8. CT202 hostname `edge-controller`;
9. CT202 onboot `0`;
10. `edge-queue-controller.service` disabled;
11. `edge-queue-controller.service` inactive;
12. no checked listener on `7070`, `8787`, or `8765`;
13. laptop controller remains live authority;
14. laptop-local DB remains live authority;
15. public routes unchanged;
16. CT202 cutover readiness gate CLOSED.

## Required backup guards

Any future mutating candidate rebuild must verify the existing HM/HN backup baseline first.

Backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Expected manifest sha256:

`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`

Expected rollback checklist sha256:

`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`

## Required preservation behavior

Before any future CT202 candidate DB replacement, the future apply phase must preserve current CT202 candidate state.

The preservation artifact must include:

- timestamp;
- candidate DB file size;
- candidate DB sha256;
- source path;
- destination path;
- reason label;
- no row content;
- no SQL dump.

The future apply phase must fail closed if candidate preservation fails.

## Target schema source design

The future candidate rebuild should target the Phase 14J-HK target schema manifest.

Target include count:

`39` laptop continuity tables.

Target omit/defer CT202-only drift tables:

- `credit_ledger`;
- `user_credit_wallets`.

Critical mismatch decisions remain:

- `workers`: target current runtime-compatible laptop shape and lane/default-off metadata columns;
- `credit_reservations`: target current runtime/laptop continuity shape, not unreviewed CT202-only extra columns.

## Data policy for future candidate rebuild

The future candidate rebuild should be schema-first and candidate-only.

No live laptop data import is authorized by this design.

No data authority path is selected by this design.

Runtime rows must not be blindly imported.

If later data movement is needed, it must be a separate explicit phase with its own approval phrase and separate evidence review.

## Future candidate rebuild output requirements

A future candidate rebuild apply phase must output:

- approval phrase confirmation;
- repo checkpoint;
- CT202 posture before mutation;
- backup artifact verification;
- candidate DB preservation artifact path and hash;
- candidate rebuild action summary;
- post-rebuild candidate DB file size and hash;
- post-rebuild schema/table summary;
- service remains disabled/inactive;
- CT202 onboot remains `0`;
- no checked listener remains active;
- CT202 cutover readiness gate remains CLOSED;
- laptop authority unchanged;
- public routes unchanged.

It must not output:

- row content;
- SQL dumps;
- raw DB contents;
- secrets;
- env file contents;
- raw private IPs;
- MAC addresses;
- auth URLs.

## Future failure handling

A future candidate rebuild apply phase must fail closed if:

- repo checkpoint is wrong;
- working tree is dirty;
- CT202 posture has drifted;
- HM/HN backup hash has drifted;
- current candidate DB cannot be preserved;
- target schema source is missing;
- post-rebuild verification fails;
- CT202 service becomes active;
- CT202 service becomes enabled;
- CT202 onboot changes from `0`;
- checked listener appears on `7070`, `8787`, or `8765`;
- public route mutation is detected.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HW - CT202 candidate rebuild apply artifact, no apply`

Suggested approval phrase:

`APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY`

That phase should create a safe no-apply artifact for the future candidate rebuild apply.

It should not execute rebuild.

It should not apply schema.

It should not import data.

It should not restore.

It should not start or enable services.

It should not mutate routes.

It should not select data authority.

## Real mutation gate remains closed

This phase intentionally does not define the real candidate rebuild approval phrase.

The future real candidate rebuild approval phrase must be defined only after the no-apply artifact exists and passes smoke.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

The CT202 candidate mutation gate remains CLOSED.

The CT202 restore gate remains CLOSED.

The CT202 schema apply gate remains CLOSED.

The data authority selection gate remains CLOSED.

Laptop controller and laptop-local DB remain live authority.

CT202 remains private candidate only.

Do not run migration/import/copy/dump from this phase.
