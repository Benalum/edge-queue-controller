# Stage 16 Companion Browser-Only Notice R3M

This checkpoint moves browser guidance and Companion feature help into a dedicated Notice section.

## Behavior

- Voice section remains controls-only:
  - Enable Voice / Disable Voice
  - Browser voice selector
- Listen section remains controls-only:
  - Start conversation mode / Stop conversation mode
  - Silence before sending
- New Notice section explains:
  - Voice and listening use the browser only.
  - Google Chrome has been tested and verified.
  - Companion can chat, speak replies, listen to drafts, run conversation mode, manage decks/cards, and assist study sessions.
- Kokoro fallback is intentionally disabled in the Companion browser UI path.

## Reason

The MVP should avoid extra network traffic and server-side resource use for voice. Browser voice/listen keeps Companion lightweight and easier to stabilize.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
