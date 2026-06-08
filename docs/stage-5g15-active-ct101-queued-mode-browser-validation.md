# Stage 5G-15 — Active CT101 queued-mode browser validation

## Goal

Correct the Stage 5G-13 post-commit validation by proving the active CT101 ChatPage actually sends the queued endpoint.

## Why

Stage 5G-13 was committed after the browser showed an assistant response, but post-commit logs showed the browser sent the legacy endpoint:

- POST /api/backend/chats/{chat_id}/messages

instead of the queued endpoint:

- POST /api/backend/chats/{chat_id}/messages/queued

This stage validates the real queued UI mode.

## Manual browser requirement

Before sending the prompt, force queued mode in DevTools:

localStorage.setItem("ai_chat_use_queued", "true");
location.href = "/chat?mode=chat";

Then confirm Network shows:

POST /api/backend/chats/{chat_id}/messages/queued

## Safety

- Does not rewrite Stage 5G-13 history.
- Does not enable wrapper app.js queued submit.
- Does not send client-provided user_id.
- Uses the CT101 ChatPage queued route only.
- Keeps rollback simple: set localStorage ai_chat_use_queued to false.
