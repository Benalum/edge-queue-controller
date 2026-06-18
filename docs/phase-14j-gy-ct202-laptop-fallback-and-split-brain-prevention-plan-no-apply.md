# Phase 14J-GY - CT202 Laptop Fallback and Split-Brain Prevention Plan - NO APPLY

Date: 2026-06-17  
Phase: 14J-GY  
Scope: CT202 laptop fallback and split-brain prevention planning only, no apply  
Previous checkpoint: Phase 14J-GX - CT202 public route and rollback plan no apply  
Previous commit: d9402ce  
Previous tag: controller-phase-14j-gx-ct202-public-route-and-rollback-plan-no-apply-2026-06-17

## Result

Phase 14J-GY documents the laptop fallback and split-brain prevention requirements before any future CT202 controller cutover.

This phase does **not** stop, pause, demote, migrate, or mutate the laptop controller.

This phase does **not** promote CT202 or approve CT202 authority.

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

## Split-brain definition

Split-brain means more than one controller authority can accept or process writes for the same logical platform state at the same time.

Examples to prevent:

- laptop controller and CT202 both accepting queue writes;
- laptop DB and CT202 DB both receiving live production writes;
- public routes sending some writes to laptop and some writes to CT202;
- workers registering against the wrong controller;
- sessions/jobs diverging between authorities;
- rollback occurring after CT202 has accepted writes that laptop does not know about.

## Fallback principle

Before any CT202 cutover apply, laptop fallback must remain available until CT202 has proven authority safely.

Fallback must preserve:

- route rollback path;
- controller process availability or restart path;
- laptop DB preservation;
- no split-brain write window;
- clear operator decision point;
- clear rollback validation.

## Future authority modes

A future cutover plan must explicitly choose one authority mode.

### Mode A - laptop authoritative, CT202 private candidate

Current mode.

Properties:

- laptop controller is live authority;
- laptop DB is live authority;
- CT202 is private and non-authoritative;
- CT202 may be inspected or temporarily rehearsed only with explicit approval;
- public routes do not point to CT202 as controller authority.

### Mode B - CT202 rehearsal, laptop still authoritative

Temporary rehearsal mode.

Properties:

- laptop controller remains live authority;
- CT202 may start temporarily for private loopback checks only;
- CT202 must not receive public production traffic;
- CT202 must not receive live writes;
- CT202 must stop after rehearsal unless separately approved;
- CT202 service remains disabled;
- CT202 onboot remains off.

### Mode C - CT202 candidate cutover window

Future apply mode only.

Properties must be defined before use:

- write freeze or routing switch sequence;
- selected data-authority path;
- runtime secret delivery;
- private CT202 health proof;
- public route switch plan;
- rollback trigger;
- split-brain prevention mechanism.

### Mode D - CT202 authoritative, laptop fallback preserved

Future post-cutover mode only.

Properties must be defined before use:

- CT202 is confirmed authoritative;
- laptop does not accept competing live writes;
- laptop fallback is available but not split-brain active;
- rollback conditions are documented;
- DB divergence handling is documented.

## Required future split-brain prevention controls

A future cutover apply must define controls for:

1. single write authority;
2. route ownership;
3. queue write gating;
4. worker registration target;
5. session behavior;
6. DB write freeze or migration boundary;
7. rollback decision timing;
8. post-rollback write reconciliation policy;
9. health validation before and after route switch;
10. explicit operator approval at each authority boundary.

## Future laptop fallback checks

Before any CT202 cutover apply, a future preflight must prove:

- laptop controller status is known;
- laptop DB quick_check is OK;
- laptop route rollback target is known;
- laptop public route or private route validation method is known;
- laptop controller restart method is known if needed;
- laptop DB backup state is known;
- laptop remains reachable by the operator;
- rollback can be performed without CT202 dependency.

## Future CT202 cutover checks

Before any CT202 authority apply, a future preflight must prove:

- CT202 service runtime is healthy privately;
- CT202 service activation policy is approved;
- CT202 secret policy is applied safely if required;
- CT202 selected data-authority path is approved;
- CT202 DB quick_check is OK;
- CT202 public route target and rollback target are approved;
- CT202 has no public Proxmox/model/worker/DB exposure;
- CT202 will not compete with laptop for writes.

## Future rollback behavior

Rollback must be safe in two scenarios.

### Scenario 1 - rollback before CT202 accepts writes

If CT202 has not accepted live production writes, rollback can return traffic to the laptop/controller path and stop CT202 runtime if needed.

Required validation:

- public route reaches rollback target;
- laptop controller responds;
- laptop DB remains authoritative;
- CT202 no longer receives public traffic;
- CT202 is stopped or private according to approved runtime plan.

### Scenario 2 - rollback after CT202 accepts writes

If CT202 has accepted writes, rollback is higher risk.

Required policy before allowing this state:

- identify which writes may have occurred;
- decide whether writes are discarded, reconciled, or preserved;
- define whether laptop can safely resume authority;
- define whether CT202 remains authority until reconciliation;
- require explicit operator decision before rollback.

A future apply phase should avoid entering Scenario 2 until data-authority and reconciliation policy are approved.

## Future route behavior

Route behavior must prevent split-brain:

- public writes must target only one controller authority;
- rollback must not create mixed routing;
- health checks must not mutate production data;
- public route switch must be atomic enough for the platform risk level;
- old route target must be verified before and after switch;
- CT202 must not receive public traffic before approval.

## Future worker behavior

Worker/model runtime remains out of scope for current CT202 migration phases.

Before worker integration later:

- workers must know exactly one controller target;
- workers must not register to both laptop and CT202;
- no worker should start during controller cutover planning;
- no CT101/model/Ollama endpoint should be called by these phases.

## Explicitly not performed in this phase

- no CT202 authority cutover;
- no CT202 public route approval;
- no CT202 data migration/import;
- no laptop DB export/import;
- no SQLite copy;
- no SQL dump;
- no table data dump;
- no live DB mutation;
- no backup creation;
- no restore operation;
- no secret generation;
- no secret printing;
- no secret file creation;
- no environment file creation;
- no systemd unit mutation;
- no `systemctl start`;
- no `systemctl enable`;
- no `systemctl daemon-reload`;
- no CT202 onboot/autostart mutation;
- no persistent controller runtime activation;
- no public route mutation;
- no Cloudflare mutation;
- no DNS mutation;
- no tunnel mutation;
- no laptop controller stop;
- no laptop controller pause;
- no CT101 call;
- no model/Ollama endpoint call;
- no worker start;
- no production DB/job mutation;
- no rerun of the Phase 14J-AG apply wrapper;
- no destructive GitHub branch/repository deletion.

## Required next no-apply phase

Next safe phase: Phase 14J-GZ - CT202 cutover readiness gate and remaining blockers summary, no apply.

Reason:

- data authority, secret policy, runtime rehearsal, public route, and fallback planning are now documented;
- a readiness gate should summarize what remains before any apply approval can be considered;
- cutover execution must still require separate explicit approval.

## Phase 14J-GY conclusion

CT202 laptop fallback and split-brain prevention planning is documented but not applied.

Laptop controller and laptop DB remain live authority.

CT202 remains private and non-authoritative.

Next safe phase: Phase 14J-GZ - CT202 cutover readiness gate and remaining blockers summary, no apply.
