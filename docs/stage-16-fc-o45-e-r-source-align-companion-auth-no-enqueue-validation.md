# Stage 16 FC-O45-E-R — Source-align Companion Auth No-Enqueue Validation

Date: 2026-06-24  
Scope: repo source/docs/smoke/commit/tag/push only  
Live deployment: none in this checkpoint

## Summary

FC-O45-E-R source-aligns the successful FC-O45-E-Q live Companion auth-validation behavior into repo source.

FC-O45-E-Q proved on CT203 that:

- signed-in bearer-session users can validate `/api/companion/chat` auth without supplying the public API key,
- `/public/companion/chat` remains public API key guarded,
- the smoke-only validation mode returns `queue_write: false`,
- `jobs_total` remains unchanged,
- no worker/model/helper/runtime call is made,
- no scheduler/timer activation occurs,
- temporary smoke sessions are cleaned up,
- DB integrity and foreign-key checks stay clean.

## Source behavior added

The previous combined handler decorated both routes:

- `/public/companion/chat`
- `/api/companion/chat`

The repo now uses route-local wrappers:

- `public_companion_chat(request)`
  - calls the shared implementation with `require_public_api_key=True`.

- `api_companion_chat(request)`
  - calls the shared implementation with `require_public_api_key=False`.

The shared implementation is:

- `_apc_companion_chat_common_fc_o45_e_q(request, *, require_public_api_key: bool)`

## No-enqueue auth validation mode

The validation mode is accepted only on the `/api/companion/chat` wrapper path when all of these are true:

1. The user is authenticated by bearer session.
2. `require_public_api_key` is false.
3. The request includes header `X-APC-Companion-Auth-Validate-Only: FC-O45-E-Q`.
4. Server env flag `EDGE_COMPANION_AUTH_VALIDATE_NO_QUEUE_ENABLED` is enabled.
5. The handler returns before context building and before the normal queue path.

Expected response shape:

    {
      "ok": true,
      "auth_validated": true,
      "queue_write": false,
      "user_id": 16,
      "route": "/api/companion/chat",
      "mode": "auth_validate_only"
    }

## Production queue behavior

Normal `/api/companion/chat` and `/public/companion/chat` behavior is unchanged except for the route-local public API key requirement. Without the validation header and server-side flag, the shared implementation continues into the normal Companion queue path.

## Safety notes

This checkpoint does not deploy live code and does not restart any service. It only records the already-proven patch in repo source, docs, and static smoke so future deploys do not lose the successful FC-O45-E-Q work.

Implementation markers:

- `APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_Q`
- `APC_COMPANION_AUTH_VALIDATE_NO_QUEUE_FC_O45_E_Q`

## Next step

After this source-align checkpoint, the next live checkpoint can safely use the no-enqueue validation mode as the preflight for a user-facing Companion test path.
