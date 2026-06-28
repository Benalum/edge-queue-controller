# Stage 16 Companion Browser Voice R3D Simplified UI

This checkpoint simplifies Companion voice controls.

## Changes

- Removes visible Kokoro controls from the Companion tab.
- Removes auto-listen from the Companion voice UI and disables it at runtime.
- Removes visible volume and speed controls from the Companion voice UI.
- Adds a browser/system voice selector populated from `window.speechSynthesis.getVoices()`.
- Saves the selected browser voice in localStorage.
- Keeps voice user-controlled through Enable Voice / Disable Voice.

## Voice policy

Provider order:

1. Browser `window.speechSynthesis`
2. Kokoro fallback only when browser speech is not supported
3. Text-only if neither path can speak

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
