# Stage 16 Companion Browser Voice R3

This checkpoint adds an explicit Enable Voice / Disable Voice flow for Companion.

## Voice policy

Voice is user-controlled.

Provider order:

1. Browser `window.speechSynthesis`
2. Kokoro fallback only when browser speech is not supported
3. Text-only when neither provider is available

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.

## Behavior

- Voice is disabled by default.
- Clicking Enable Voice saves the setting in localStorage.
- If browser speech is available, replies speak locally in the user's browser.
- If browser speech is unavailable, the UI selects Kokoro fallback, but Kokoro only works when the backend endpoint is available.
- Clicking Disable Voice cancels browser speech and prevents future reply speech.
