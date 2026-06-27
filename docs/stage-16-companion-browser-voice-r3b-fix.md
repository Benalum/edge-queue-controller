# Stage 16 Companion Browser Voice R3B Fix

This checkpoint fixes the incomplete R3 browser voice checkpoint.

## Why R3B exists

R3 created docs and a tag, but the companion source patch did not land because the patch searched for a non-existent `collectVoiceSettings` function. R3B applies the actual browser voice implementation.

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
