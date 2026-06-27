# Stage 16 Companion Browser Voice R3C Real Patch

This checkpoint fixes the incomplete R3/R3B browser voice checkpoints and applies the actual Companion browser voice implementation.

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
