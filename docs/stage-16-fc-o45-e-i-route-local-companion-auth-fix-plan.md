# Stage 16 FC-O45-E-I — Route-local Companion auth fix plan

## Purpose

Design the next Companion text-chat auth repair without touching live code. This plan replaces the failed FC-O45-E-F global public API key guard patch with a route-local split.

## Current confirmed state

- Public service was restored in FC-O45-E-F-R5.
- Repo checkpoint `37d3269` preserves the failed FC-O45-E-F patch as a diagnostic artifact.
- Live CT203 backend is marker-free and healthy again.
- `/api/system/status` is public healthy.
- `/api/me` is signed-out guarded.
- `/api/companion/chat` exists but signed-in browser POST currently fails before useful Companion behavior because the route requires the public API key.

## Why FC-O45-E-F failed

FC-O45-E-F modified the global `_require_public_api_key` guard. The first deploy malformed the function by injecting literal `\n` text inside the function body. A later repair still produced public API failures. The rollback proved the safe lesson:

Do not modify the global public API key guard for this feature.

## Safer design

Use a route-local auth split:

1. Keep `/public/companion/chat` protected by `_require_public_api_key(request)`.
2. Make `/api/companion/chat` authenticate through the existing bearer-session user resolver only.
3. Do not put `EDGE_PUBLIC_API_KEY` or any trusted gateway secret into browser JavaScript.
4. Do not modify `_require_public_api_key`.
5. Do not enable workers, timers, schedulers, helpers, model calls, or persistent runtime.
6. Preserve signed-out behavior:
   - signed-out `/api/companion/chat` POST returns 401.
   - signed-out `/public/companion/chat` POST returns 401.
7. Signed-in `/api/companion/chat` may return either:
   - an immediate disabled/feature-not-enabled response if legacy local job creation remains disabled, or
   - one queued job if existing endpoint behavior queues it.
8. If a smoke creates a job, cleanup must delete only the smoke marker job/result/session rows.

## Implementation shape

Preferred source shape, shown as indented pseudo-code to avoid nested markdown fence issues:

    async def _companion_chat_common(request: Request, *, require_public_api_key: bool):
        if require_public_api_key:
            await _require_public_api_key(request)
        user_row = existing_bearer_user_resolver(request)
        ...

Then define separate route handlers:

    @app.post("/public/companion/chat")
    async def public_companion_chat(request: Request):
        return await _companion_chat_common(request, require_public_api_key=True)

    @app.post("/api/companion/chat")
    async def api_companion_chat(request: Request):
        return await _companion_chat_common(request, require_public_api_key=False)

The exact existing user resolver name must be discovered from the current source before patching. The implementation must reuse the same resolver the existing Companion route already calls after public API key validation.

## Static gates before deploy

Before any live deploy, the patch must prove:

- `_require_public_api_key` source is unchanged except for unrelated formatting if any.
- No `APC_COMPANION_BEARER_SESSION_AUTH_FC_O45_E_F` marker remains in `edge_controller.py`.
- `/public/companion/chat` route handler calls `_require_public_api_key`.
- `/api/companion/chat` route handler does not call `_require_public_api_key`.
- The shared Companion function calls the existing bearer-session user resolver.
- Python compile succeeds.
- The patch does not introduce public API key or trusted edge secret into frontend/static files.

## Live gates after deploy, only with explicit approval

After approval for a live backend change:

1. Backup CT203 live `edge_controller.py`.
2. Deploy repaired backend source.
3. Restart only `edge-queue-controller.service`.
4. Verify:
   - `/api/system/status` HTTP 200.
   - signed-out `/api/me` HTTP 401.
   - signed-out `/api/companion/chat` POST HTTP 401.
   - signed-out `/public/companion/chat` POST HTTP 401.
5. Create temporary bearer session for app_users ID 16.
6. POST once to `/api/companion/chat` with a unique smoke marker.
7. Accept 200/201/202 if no worker/model/helper/runtime call is made.
8. Cleanup only the temporary smoke session and any smoke job/result rows.
9. Verify DB integrity and FK checks.
10. Commit/tag/push only after smoke passes.

## Explicit non-goals

- No global public API guard mutation.
- No browser public API key injection.
- No model runtime call.
- No helper/worker activation.
- No scheduler/timer activation.
- No CT/VM restart.
- No nginx/cloudflared mutation.
