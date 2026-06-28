# Stage 16 Companion Conversation Mode R3G

This checkpoint adds browser-only Conversation Mode to Companion.

## Behavior

Conversation mode:

1. Listens through browser SpeechRecognition.
2. Pastes speech into the message box.
3. Auto-sends after 5 seconds of silence.
4. Speaks Sol's reply through browser speechSynthesis.
5. Starts listening again after Sol finishes speaking.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
