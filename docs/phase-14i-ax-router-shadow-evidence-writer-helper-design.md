# Phase 14I-AX Router Shadow Evidence Writer Helper Design

Phase 14I-AX is a docs/smoke-only design gate for a future router shadow evidence writer helper.

## Scope

This phase designs the future writer helper contract after the Phase 14I-AW controlled schema apply.

This phase does not add writer code.

This phase does not change runtime behavior.

## Current State Before Any Writer Exists

- `queued_chat_router_shadow_evidence` schema has been applied to the controller-owned database.
- The queued-chat router shadow helper is wired but default-off.
- The shadow helper return value is still discarded.
- Live requested_model pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No runtime router shadow evidence persistence exists.
- No writer helper exists.
- Router model selection remains disabled.
- CT101 remains protected.

## Future Writer Helper Goal

A later phase may add a small writer helper that records sanitized router shadow evidence for audit and rollout safety.

The future writer must be:

- default-off,
- fail-closed/no-block,
- privacy-filtered,
- controller-owned only,
- bounded to allowlisted fields,
- safe if the database is unavailable,
- separate from router activation,
- separate from browser exposure,
- separate from model selection changes.

## Proposed Future Helper Names

The future implementation may use names such as:

- `_phase14i_writer_gate_enabled()`
- `_phase14i_router_shadow_evidence_payload_from_decision(...)`
- `_phase14i_record_router_shadow_evidence(...)`

These names are design notes only in this phase. They must not exist in runtime code yet.

## Future Environment Gate

A future writer phase should use a new default-off environment flag.

Proposed flag:

- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED`

Default behavior:

- unset = disabled,
- empty = disabled,
- `0` = disabled,
- `false` = disabled,
- `true` or `1` = enabled only after explicit approval.

## Future Write Timing

The future writer should run only after the shadow decision helper returns a safe structured decision.

The future writer must not block the live queued-chat request.

If the writer fails, the live queued-chat request must continue unchanged.

## Future Allowed Fields

The future writer may record only bounded metadata fields such as:

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
- related job id when safe and already available,
- writer gate enabled state,
- created timestamp.

## Future Forbidden Fields

The future writer must never persist:

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

## Future Failure Behavior

The future writer must be no-block.

Allowed failure behavior:

- catch exception,
- log only a generic bounded warning,
- return false or a bounded status,
- continue existing queued-chat flow unchanged.

Forbidden failure behavior:

- raising into the live queued-chat request,
- retry loops inside the request path,
- exposing writer failure to the browser,
- falling back to raw payload persistence,
- calling a model to repair missing fields.

## Future Validation Requirements

Before adding runtime writer code, a later phase must provide:

- static smoke for writer markers,
- privacy allowlist smoke,
- default-off behavior smoke,
- no-browser-output smoke,
- no-live-model-call smoke,
- no-CT101-mutation smoke,
- no-job-23-mutation smoke.

Live DB write validation must be a separate explicitly approved gate.

## Still Parked After This Phase

This phase keeps the following parked:

- runtime writer implementation,
- runtime persistence,
- browser exposure,
- router model selection,
- router activation,
- scheduler behavior changes,
- CT101 mutation,
- live model validation.
