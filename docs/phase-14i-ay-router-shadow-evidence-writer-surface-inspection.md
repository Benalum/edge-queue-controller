# Phase 14I-AY Router Shadow Evidence Writer Surface Inspection

Phase 14I-AY is a docs/smoke-only inspection phase for the future router shadow evidence writer implementation surface.

## Scope

This phase inspects and records where a future default-off writer helper should fit.

This phase does not add writer code.

This phase does not write to the database.

This phase does not change runtime behavior.

## Current State

- Phase 14I-AW applied the controller-owned `queued_chat_router_shadow_evidence` schema.
- Phase 14I-AX designed the future writer helper contract.
- The queued-chat router shadow decision helper is wired.
- The helper remains default-off through `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`.
- The shadow helper return value remains discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No runtime persistence exists.
- No writer helper exists.
- Router model selection remains disabled.
- CT101 remains protected.

## Inspected Runtime Surface

The future writer surface is the controller-owned queued-chat path in `edge_controller.py`.

The important existing static markers are:

- `_phase14iag_queued_chat_router_shadow_enabled`
- `_phase14iag_queued_chat_router_shadow_decision`
- `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`

The current route behavior must remain unchanged until a separate implementation phase is approved.

## Future Insertion Point

A later writer implementation phase may add a bounded writer call after the shadow decision helper returns a safe structured decision.

The future writer call must happen only after the live route has already built the safe metadata needed for the shadow decision.

The future writer must not alter:

- live `requested_model`,
- queued job payload semantics,
- browser response body,
- queue enqueue behavior,
- guardrail behavior,
- CT101 behavior,
- model selection behavior,
- scheduler behavior.

## Future Writer Control Flow

Proposed future control flow:

1. Build existing queued-chat guard payload.
2. Call existing shadow decision helper.
3. Keep live route behavior unchanged.
4. If future writer gate is enabled, construct an allowlisted evidence payload.
5. Attempt a bounded insert into `queued_chat_router_shadow_evidence`.
6. On writer failure, log only a generic bounded warning.
7. Continue live queued-chat flow unchanged.

## Future Writer Helper Surfaces

A future implementation may add separate helpers for:

- writer environment gate,
- allowlisted evidence payload construction,
- bounded insert execution,
- generic no-block failure handling.

The helpers must be small and individually smoke-tested.

## Future Default-Off Gate

A future implementation should use:

- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED`

Required default behavior:

- unset means disabled,
- empty means disabled,
- `0` means disabled,
- `false` means disabled,
- only explicit approved truthy values may enable writes.

## Future Allowlist Boundary

The future writer may persist only small bounded metadata.

Allowed examples:

- request surface,
- route name,
- guardrail decision status,
- live requested model label,
- router recommended model label,
- router policy version,
- router decision status,
- router confidence bucket,
- escalation reason code,
- fallback reason code,
- related job id when already safe,
- writer gate enabled state,
- created timestamp.

## Future Forbidden Boundary

The future writer must not persist:

- raw prompts,
- raw messages,
- raw request bodies,
- full queue payloads,
- full job payloads,
- raw context dumps,
- cookies,
- auth headers,
- bearer tokens,
- passwords,
- secrets,
- personal provider tokens,
- unbounded user content.

## Future Failure Boundary

The future writer must be no-block.

The writer must not:

- raise into the live request path,
- retry inside the request path,
- return writer internals to the browser,
- expose SQL errors to users,
- call models,
- mutate CT101,
- mutate job 23,
- change scheduler behavior.

## Required Later Gates

Before runtime writer implementation, a later phase must explicitly approve:

- adding writer helper code,
- adding default-off writer gate code,
- adding static writer smokes,
- validating disabled behavior,
- validating no browser exposure.

Before any live write validation, a still later phase must explicitly approve:

- DB write validation,
- count-only verification,
- rollback plan,
- privacy allowlist check.

## Decision After This Phase

After Phase 14I-AY, the safe choices are:

- proceed to Phase 14I-AZ park-or-proceed decision gate,
- implement default-off writer helper in a separate gated phase,
- park router evidence work and return to persistent lane worker blocker re-entry.
