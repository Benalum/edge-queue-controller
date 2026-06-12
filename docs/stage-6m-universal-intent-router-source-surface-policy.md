# Stage 6M Universal Intent Router Source Surface Policy

Stage 6M adds a source/surface policy layer to the Universal Intent Router dry-run helper.

The endpoint remains disabled by default.

## Purpose

The router should only classify safe user-facing input surfaces.

It must not be usable as a generic pathway into admin, auth, power, worker, internal, or system operations.

## Allowed behavior

The policy allows normal user-facing surfaces such as:

- Study
- Companion
- Chat
- blank general user input

Blank source/surface values are treated as general user input so existing safe fixture behavior remains stable.

## Blocked behavior

The policy blocks restricted surfaces and source values such as:

- admin
- auth
- internal
- power
- security
- system
- worker
- queue
- password
- billing
- account-bootstrap

Blocked inputs return:

- `intent.name=unknown.unsupported`
- `target.existing_route=null`
- `source_surface_policy.allowed=false`
- `decision_trace[-1].rule_id=policy.source_surface.blocked`

## Safety

The router still never dispatches.

The router still never calls a model.

The router still never mutates state.

The router still returns:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`

## Stage boundary

Stage 6M adds only dry-run policy metadata and blocked-source classification.

Stage 6M does not wire the router into any page.

Stage 6M does not enable dispatch.

Stage 6M does not enable model calls.
