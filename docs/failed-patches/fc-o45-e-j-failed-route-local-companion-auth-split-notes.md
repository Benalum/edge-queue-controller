# FC-O45-E-J failed route-local Companion auth split artifact

## Scope

This artifact preserves the local failed E-J route-local Companion auth split patch before resetting `edge_controller.py` back to HEAD `7cf455f`.

## Why it is preserved

The E-J patch passed local static gates and deployed to CT203, but public smoke failed after restart:

- `/api/system/status` returned HTTP 502.
- `/api/me` returned HTTP 502.
- signed-out `/api/companion/chat` returned HTTP 401.
- signed-out `/public/companion/chat` returned HTTP 401.
- The signed-in Companion smoke did not run.
- No smoke DB rows were intentionally created by the E-J smoke.

## Rollback result

FC-O45-E-J-R2 restored CT203 `edge_controller.py` from the pre-E-J backup and restarted only `edge-queue-controller.service`.

Post-rollback public checks passed:

- `/api/system/status` HTTP 200.
- `/api/me` HTTP 401.
- signed-out Companion guards HTTP 401.
- E-J marker absent from live CT203 backend.
- E-F failed marker absent from live CT203 backend.

## Preserved patch

- Patch file: `docs/failed-patches/fc-o45-e-j-failed-route-local-companion-auth-split.patch`
- Patch sha256: `ee8bfe3a0bd57ccda27a936a1594ffdb5f0c443ceb6d403cab49dee0307a2db8`
- Expected failed marker: `APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_J`

## Safety conclusion

Do not retry this exact route split. The next step should be read-only traceback/source diagnosis to identify why splitting the combined FastAPI route caused public 502s, before any new live backend patch.
