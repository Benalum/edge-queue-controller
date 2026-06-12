# Stage 7S Real Authenticated Shadow Comparison Success

Stage 7S records the first successful real authenticated shadow comparison for Study and Companion.

This stage does not enable Universal Intent Router runtime dispatch.

This stage does not wire the router into production routes.

This stage does not enable router model calls.

## Preconditions

- Stage 7P fixed controller responsiveness by offloading Proxmox inventory SSH from the async event loop.
- Stage 7Q fixed the frontend auth-ready rerender bug caused by an out-of-scope `cleanRoute` reference.
- Stage 7R updated the authenticated comparison runner to support `x-edge-api-key`.
- Power automation remained paused during this test with `EDGE_POWER_AUTO_PAUSED=1`.

## Runtime Auth Inputs

The authenticated comparison used runtime-only secrets:

- Browser `edgeStudyToken` as bearer auth.
- `.env` `EDGE_PUBLIC_API_KEY` as the `x-edge-api-key` header.

Secret handling result:

- Auth values were not printed.
- Auth values were not stored.
- Raw existing-route responses were not stored.
- Comparison artifacts remained ignored by git.

## Successful Checks

The lightweight auth route confirmed the bearer token:

- `/system/session/me`
- HTTP 200

The direct Study route confirmed both headers worked together:

- `/api/study/session/command`
- HTTP 200

## Authenticated Shadow Comparison Results

Study:

- Domain: `study`
- Existing route: `/api/study/session/command`
- Existing route HTTP status: 200
- Existing route response class: `existing_route_json_response`
- Shadow intent: `study.next`
- Shadow rule id: `study.next.alias`
- Router dispatch performed: false
- Router model call required: false
- Raw response stored: false
- Secrets stored: false
- Safe to continue: true

Companion:

- Domain: `companion`
- Existing route: `/api/companion/chat`
- Existing route HTTP status: 200
- Existing route response class: `existing_route_json_response`
- Shadow intent: `companion.chat`
- Shadow rule id: `companion.chat.text`
- Router dispatch performed: false
- Router model call required: false
- Raw response stored: false
- Secrets stored: false
- Safe to continue: true

## Conclusion

The Universal Intent Router authenticated shadow comparison foundation is now proven against real authenticated Study and Companion route calls.

The router can classify intended behavior while existing routes remain the only code path that performs user-visible work.

## Remaining Follow-ups

Power automation remains paused and should not be resumed until the Proxmox SSH inventory timeout is investigated.

The Proxmox inventory timeout itself still needs a separate fix, but it no longer blocks login, health, Study, Companion, or other controller routes after Stage 7P.
