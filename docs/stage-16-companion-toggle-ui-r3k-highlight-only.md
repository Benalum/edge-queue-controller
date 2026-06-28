# Stage 16 Companion Toggle UI R3K Highlight Only

This checkpoint simplifies Companion voice/listen toggle feedback.

## Behavior

- Voice Enable/Disable no longer writes status messages into the chat.
- Conversation Start/Stop no longer writes status messages into the chat.
- The active state is shown by the highlighted button.
- Voice defaults to disabled.
- Conversation mode defaults to stopped.
- The text above Voice and Listen toggle buttons is removed.
- Existing conversation mode, listen-to-draft, and silence-delay behavior remain.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
