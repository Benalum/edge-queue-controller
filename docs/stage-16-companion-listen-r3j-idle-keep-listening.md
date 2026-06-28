# Stage 16 Companion Listen R3J Idle Keep Listening

This checkpoint fixes browser listening idle behavior.

## Behavior

- Conversation mode keeps listening if no speech has been heard yet.
- Listen to draft keeps listening if no speech has been heard yet.
- Browser `no-speech` events restart listening quietly instead of stopping the session.
- The silence delay only starts after recognized text exists.
- Once text exists, conversation mode still auto-sends after the configured silence delay.
- Once text exists, draft mode still preserves the draft for manual send.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
