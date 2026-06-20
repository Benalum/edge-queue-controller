# Stage 15-D — Mock Queued Chat Compatibility Apply

Date: 2026-06-19  
Base checkpoint: Stage 15-C / HEAD `c20f682`  
Approval: `APPROVE_STAGE_15_D_MOCK_QUEUED_CHAT_COMPATIBILITY_APPLY_NO_MODEL_NO_WORKER_NO_SCHEDULER`

## Scope

This apply adds mock/no-model frontend-compatible queued chat routes to the CT203 controller.

Routes added:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`
- `GET /api/chat/queue/status`

## Safety boundaries

Allowed:

- backend source mutation
- deploy patched `edge_controller.py` to CT203 current release
- restart only `edge-queue-controller.service` if syntax checks pass
- validate route presence and unauthenticated behavior
- bounded DB count reads

Not allowed:

- Ollama calls
- `/tick/ollama-direct` calls
- live model endpoint calls
- worker activation
- scheduler activation
- DB schema migration
- router evidence writes
- CT204 start
- private storage unlock/mount
- PVESO mutation
- nginx/cloudflared mutation
- Cloudflare/DNS/tunnel mutation
- CT/VM reboot

## Implementation

The patch adds a Stage 15-D marked block before legacy `/public/jobs` routes.

The new routes require:

- public API key guard through existing `_require_public_api_key(request)`
- current user/session through existing `_auth_current_user_from_request(request)`

The create route inserts a single `jobs` row for authenticated requests:

- `job_type=companion.chat`
- `requested_model=mock/no-model`
- `status=queued`
- `attempts=0`
- `user_id=<authenticated user>`

The Decision Maker is in-memory only for this first apply. It does not write `router_logs`, `router_resolution_steps`, or `router_feedback`.

## Validation note

This phase validates route presence and safe unauthenticated behavior. Authenticated browser/session validation remains the next bounded validation step if no usable session token is available inside PPB without exposing credentials.

## Result

Mock/no-model queued chat compatibility is implemented without worker, scheduler, Ollama, or model activation.
