# Frontend Queued Chat UI Wiring Map — Stage 5F-28

## Purpose

Stage 5F-28 maps the exact frontend hook points needed for future queued-chat UI wiring.

This stage is inspection and planning only.

This stage does not change frontend runtime behavior.

This stage does not import queued_chat_status.js.

This stage does not enable queued chat by default.

## Inputs

- docs/frontend-queued-chat-ui-wiring-inspection.md
- docs/frontend-queued-chat-polling-plan.md
- docs/frontend-queued-chat-status-helper.md
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/index.html
- frontend/wrapper-ui/dev_server.py
- frontend/wrapper-ui/queued_chat_status.js

## Current proven frontend foundation

Already proven:

- queued_chat_status.js exists
- queued_chat_status.js is unimported
- queued_chat_status.js can normalize queued, running, complete, failed, and cancelled states
- queued_chat_status.js can decide polling delay
- queued_chat_status.js can extract completed assistant replies
- no frontend runtime behavior has changed

## Required future hook points

Future frontend queued-chat UI wiring needs these hook points:

1. current chat submit function
2. current user message render function
3. current assistant message render function
4. current loading or pending assistant placeholder
5. current error display behavior
6. current model selection behavior
7. current conversation/chat id state
8. current auth/session behavior
9. current fetch wrapper or API helper
10. current retry or resend behavior if present

## Queued mode feature flag

Queued chat UI must be disabled by default.

Recommended frontend runtime gate:

- window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true

or an equivalent server-provided config value.

The frontend must preserve the current non-queued chat path when the flag is off.

## Future queued send behavior

When queued mode is enabled, future frontend behavior should be:

1. render user message immediately
2. POST to /api/chat/queued
3. store job_id, chat_id, and user_message_id in local UI state
4. render assistant placeholder with queued status
5. poll GET /api/chat/queued/{job_id}
6. update placeholder as queued, running, complete, failed, or timed out
7. render assistant reply only after complete
8. avoid duplicate assistant messages on repeated polling or refresh

## Future rollback behavior

If queued mode fails or is disabled:

- use existing non-queued chat path
- do not send user_id
- do not send X-Synthetic-User-Id
- do not create duplicate user messages
- do not create duplicate assistant messages
- do not delete queued jobs

## Security behavior

The frontend must not send user_id.

The frontend must not send authenticated_user_id.

The frontend must not send X-Synthetic-User-Id in real-user mode.

The frontend should rely on normal authenticated session behavior.

## Required future smokes

Before live UI behavior changes:

- queued helper imported but flag off smoke
- flag off preserves current chat path smoke
- flag on creates queued job smoke
- queued status placeholder smoke
- completed assistant render smoke
- failed job render smoke
- offline queued render smoke
- duplicate polling does not duplicate assistant message smoke
- rollback disables queued UI smoke

## Recommended Stage 5F-29

Stage 5F-29 should import queued_chat_status.js in index.html while proving the queued UI path remains disabled by default.

Stage 5F-29 should not change chat send behavior yet.

## What this stage does not do

This stage does not:

- change frontend runtime behavior
- import queued_chat_status.js
- enable queued chat by default
- submit real production queued jobs
- start persistent workers
- call CT101
- call Ollama directly
- persist assistant messages
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
