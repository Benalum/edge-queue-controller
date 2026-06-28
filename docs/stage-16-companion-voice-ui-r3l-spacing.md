# Stage 16 Companion Voice UI R3L Spacing

This checkpoint improves spacing in the Companion Voice section.

## Behavior

- Adds spacing below the Enable Voice / Disable Voice buttons.
- Moves the Browser voice selector into its own padded row.
- Keeps the highlighted button state behavior from R3K.
- Keeps browser voice output behavior unchanged.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
