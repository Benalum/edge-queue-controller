# Stage 16 Companion Browser-Only Voice R3M

This checkpoint removes the server-side Kokoro fallback path from the browser Companion MVP.

## Behavior

- Voice output uses browser `speechSynthesis` only.
- Listening uses browser `SpeechRecognition` / `webkitSpeechRecognition` only.
- Kokoro fallback is intentionally disabled in the Companion browser UI path.
- The Voice section now includes guidance that Google Chrome has been tested and verified.
- The Browser voice selector has improved spacing below the voice toggle buttons.

## Reason

The MVP should avoid extra network traffic and server-side resource use for voice. Browser voice/listen keeps the Companion lightweight and easier to stabilize.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
