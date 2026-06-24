# Stage 16 FC-O44-C-R5 record public System status redaction and Study/banner audit

Date: 2026-06-24

## Result

This checkpoint records that the public System status redaction is live and source-backed after the FC-O44-C recovery sequence.

The public status API now exposes only user-facing service availability and plain-language impact. It no longer exposes infrastructure members, storage internals, model memory internals, admin model action internals, backend URLs, backend paths, implementation services, or host/container labels.

## Study/banner audit result

A separate public UI issue remains:

- Signed-out users can see Study session scaffolding.
- Public Study should not render session status, queue/session fields, selected deck IDs, deck selector state, or empty authenticated deck state.
- Public Study should render only a public overview and sign-in prompt until authenticated.
- Banner copy should be shortened to: `Under Construction: Some features do not work yet.`

## Mutation boundary

Performed:

- repo checkpoint for the already-live public status source redaction,
- public read-only smoke,
- read-only Study/banner source audit,
- commit/tag/push.

Not performed:

- no new live UI mutation,
- no CT203 source deploy,
- no service restart,
- no DB write,
- no job mutation,
- no worker/model/runtime mutation,
- no reset-failed.

## Next recommended stage

FC-O44-D should patch the public Study signed-out view and banner copy, then deploy through the correct frontend/static path found by the audit.
