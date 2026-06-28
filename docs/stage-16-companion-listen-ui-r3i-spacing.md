# Stage 16 Companion Listen UI R3I Spacing

This checkpoint improves spacing in the Companion Listen section.

## Behavior

- Adds spacing below the conversation mode buttons.
- Moves the silence delay control into its own padded row.
- Keeps the existing conversation mode behavior and configurable silence delay.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
