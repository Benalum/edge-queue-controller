# Phase 14I-AZ Router Shadow Evidence Park-or-Proceed Checkpoint

Phase 14I-AZ is a docs/smoke-only checkpoint after the router shadow evidence schema apply, writer design, and writer surface inspection.

## Scope

This phase records the decision boundary before either:

- implementing a default-off router shadow evidence writer in a later gated phase, or
- parking router evidence work and returning to persistent lane worker blocker re-entry.

This phase does not add writer code.

This phase does not write to the database.

This phase does not change runtime behavior.

This phase does not activate router model selection.

## Current Completed Router Evidence State

Completed checkpoints:

- Phase 14I-AW applied the controller-owned `queued_chat_router_shadow_evidence` schema.
- Phase 14I-AX designed the future writer helper contract.
- Phase 14I-AY inspected the future writer implementation surface.

Current runtime state:

- queued-chat router shadow helper is wired,
- router shadow helper remains default-off,
- helper return value remains discarded,
- live `requested_model` pass-through remains unchanged,
- no router shadow output is returned to the browser,
- no runtime writer exists,
- no runtime router shadow evidence persistence exists,
- router model selection remains disabled,
- CT101 remains protected.

## Option A: Proceed to Writer Implementation Later

A later writer implementation phase may be reasonable only if explicitly approved.

Required boundaries for that future phase:

- default-off writer gate,
- no browser exposure,
- no live model calls,
- no CT101 mutation,
- no scheduler changes,
- no router activation,
- no job 23 mutation,
- no raw prompts,
- no raw messages,
- no raw request bodies,
- no queue payloads,
- no full job payloads,
- no cookies,
- no auth headers,
- no bearer tokens,
- no secrets.

The future writer must be fail-closed/no-block and must write only allowlisted bounded metadata.

## Option B: Park Router Evidence Now

Router evidence can safely be parked now because:

- the schema exists,
- the schema has been applied,
- the future writer contract has been designed,
- the future writer surface has been inspected,
- runtime behavior remains unchanged,
- router activation remains parked.

Parking means no writer implementation is added yet.

## Recommended Next Major Part

The recommended next major part is persistent lane worker blocker re-entry.

Reason:

- persistent lane workers remain a blocker,
- primary worker filtering remains a blocker,
- router rollout remains parked,
- warmup execution remains disabled,
- CT101 remains protected.

## Next Safe Startup After Parking

The next phase should begin with a read-only baseline and static inspection for persistent lane worker re-entry.

It should not:

- enable router model selection,
- enable model warmup execution,
- mutate CT101,
- call live model endpoints,
- mutate job 23,
- expose router shadow evidence to the browser,
- add router evidence writer code unless separately approved.

## Checkpoint Summary

After this phase, the project can safely move from router shadow evidence preparation back to lane worker stability work.
