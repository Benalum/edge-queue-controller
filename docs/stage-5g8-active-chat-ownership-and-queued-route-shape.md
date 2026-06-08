# Stage 5G-8 — Active chat ownership and queued route shape

## Goal

Prevent accidental wiring into the wrong frontend form and identify the real active chat submit owner.

## Findings

- wrapper app.js authForm is login/register, not chat.
- /chat is currently in FULL_APP_ROUTES, so logged-in /chat is proxied to CT101 frontend.
- The active live chat submit path is CT101 frontend/components/ChatPage.tsx.
- CT101 ChatPage already has a queued chat mode and calls /api/backend/chats/{chat_id}/messages/queued.
- Wrapper app.js queued helper is proven through the wrapper, but it is not currently the live /chat UI.

## Safety

This stage does not wire live submit.
This stage does not change queued chat defaults.
This stage blocks accidental queued wiring into authForm.
This stage preserves legacy and CT101 chat behavior.
