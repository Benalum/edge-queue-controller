# Stage 16 Companion Browser Listen R3E

This checkpoint adds browser-side listening to Companion.

## Behavior

- Adds a Listen section using browser `SpeechRecognition` / `webkitSpeechRecognition`.
- Adds `Listen and auto-send`, which pastes speech into the message box and sends it after 5 seconds of silence.
- Adds `Listen to draft`, which pastes speech into the message box and waits for the user to press Send.
- Adds a `Listen to draft` button below the Send button.
- Adds `Stop listening`.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
