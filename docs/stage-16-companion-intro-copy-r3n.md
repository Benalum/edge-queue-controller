# Stage 16 Companion Intro Copy R3N

This checkpoint updates the Companion intro/help message.

## New message

I’m here with you. You can talk with me, study flashcards, and manage your decks.

To study, try saying things like “list decks,” “select deck [deck name],” “start study,” or “show current card.” You can also create, edit, delete, and flag cards.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
