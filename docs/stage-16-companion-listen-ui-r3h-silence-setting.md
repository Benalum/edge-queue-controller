# Stage 16 Companion Listen UI R3H Silence Setting

This checkpoint simplifies the Companion Listen section and adds a configurable silence delay.

## Behavior

The Listen section now focuses on conversation mode:

- Start conversation mode
- Stop conversation mode
- Silence before sending, default 5 seconds

The manual Listen-section buttons for `Listen and auto-send`, `Listen to draft`, and `Stop listening` are removed from the Listen section.

The separate `Listen to draft` button below Send remains available for manual dictation.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
