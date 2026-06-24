# Stage 16 FC-O45-E-P — Companion Auth No-Enqueue Validation Plan

Date: 2026-06-24  
Scope: repo-only no-apply implementation plan  
Status: planning artifact only

## Purpose

FC-O45-E-N proved that the route-local Companion auth split can allow an authenticated bearer-session user to reach `/api/companion/chat` without the public API key while keeping the public/signed-out guard intact.

It also proved that `/api/companion/chat` is not a safe auth-only smoke target today because a successful POST enqueues an `ollama_chat` job. In FC-O45-E-N, direct CT203 signed-in smoke created queued job `122` with `requested_model=no-model-smoke`. FC-O45-E-N-R3 cleaned that up and rolled the live backend back to marker-free source.

The next implementation should separate auth validation from queue submission so we can prove the API/auth contract without writing to `jobs`.

## Current baseline after recovery

Safe baseline expected before implementation:

- Repo remains clean at `902af06`.
- CT203 controller is active.
- Live CT203 source has no `APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_J` marker.
- Public `/api/system/status` returns 200.
- Public `/api/me` returns 401 signed out.
- Public signed-out `/api/companion/chat` returns 401.
- DB integrity is `ok`.
- `foreign_key_check` is clean.
- `jobs_total` is back to 117.
- Job `122` is absent.
- FC-O45-E-N smoke sessions are absent.

## Design goals

1. `/public/companion/chat` must remain public API key guarded.
2. `/api/companion/chat` should allow authenticated bearer-session users without requiring the public API key.
3. Auth validation smoke must be possible without queue writes.
4. The default production Companion POST path must still enqueue normally unless an explicit smoke-only validation mode is enabled.
5. No worker, model, helper, runtime, scheduler, or timer should be invoked during auth-validation smoke.
6. No public API key should be placed in browser-visible frontend code.

## Proposed route shape

Replace the current combined route handler:

- `@app.post("/public/companion/chat")`
- `@app.post("/api/companion/chat")`
- `public_companion_chat(...)`

with separate wrappers and a shared implementation:

- `@app.post("/public/companion/chat")`
  - Require public API key.
  - Require bearer-session user.
  - Call shared Companion chat implementation.

- `@app.post("/api/companion/chat")`
  - Require bearer-session user.
  - Do not require public API key.
  - Call shared Companion chat implementation.

The shared implementation should hold the normal queue-submission behavior.

## Proposed no-enqueue validation mode

Add a smoke-only no-enqueue mode that is accepted only when all of these are true:

1. Request path is `/api/companion/chat`, not `/public/companion/chat`.
2. Request has a valid bearer-session authenticated user.
3. Request includes a narrow validation header, for example `X-APC-Companion-Auth-Validate-Only: FC-O45-E-Q`.
4. A server-side environment flag is enabled, for example `EDGE_COMPANION_AUTH_VALIDATE_NO_QUEUE_ENABLED=1`.
5. The request body includes a harmless smoke marker message.
6. The handler returns before any `jobs` insert or queue write.

Suggested response shape, written here without a Markdown code fence so this file can be generated safely from shell heredocs:

    {
      "ok": true,
      "auth_validated": true,
      "queue_write": false,
      "user_id": 16,
      "route": "/api/companion/chat",
      "mode": "auth_validate_only"
    }

This gives us a reliable smoke target that proves auth and route behavior without changing queue state.

## Safety constraints for implementation

The implementation phase must use a separate approval because it mutates live backend code and restarts CT203 controller.

Implementation must explicitly forbid:

- worker/model/helper/runtime call
- scheduler/timer activation
- CT/VM restart
- nginx/cloudflared mutation
- DB writes except temporary smoke session rows and cleanup
- queue writes during auth-validation smoke
- public API key exposure in frontend assets

## Proposed smoke sequence for the implementation phase

1. Preflight:
   - repo/head/origin clean
   - public health 200/401 baseline
   - CT203 local health 200
   - DB integrity ok/FK clean
   - jobs count baseline captured

2. Backup and patch:
   - backup live `edge_controller.py`
   - apply route split and no-enqueue validation mode
   - compile with CT203 venv Python
   - restart only `edge-queue-controller.service`
   - require repeated CT203-local `/system/status` 200

3. Auth-validation smoke:
   - create temporary bearer session rows for user 16
   - POST direct CT203 `/api/companion/chat` with validation header
   - expect 200 and `queue_write=false`
   - require jobs count unchanged
   - require no job_results created
   - run laptop-side public health checks
   - POST laptop-side public `/api/companion/chat` with same bearer token and validation header
   - expect 200 and `queue_write=false`
   - require jobs count unchanged
   - cleanup temporary session rows

4. Guard checks:
   - signed-out `/api/companion/chat` remains 401
   - signed-out `/public/companion/chat` remains 401
   - `/public/companion/chat` still requires public API key
   - no validation mode accepted on `/public/companion/chat`
   - no validation mode accepted without server-side env flag

5. Rollback:
   - If readiness or smoke fails, restore marker-free source backup.
   - Restart only `edge-queue-controller.service`.
   - Verify public health and DB cleanup.

## Decision

Do not retry live `/api/companion/chat` auth split with the normal POST body as the smoke target. Use a no-enqueue auth-validation mode first, then separately test normal queue behavior under an approval that allows one temporary queued job and cleanup.
