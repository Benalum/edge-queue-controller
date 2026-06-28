# Stage 16 Companion Browser Listen R3F Preserve Submit

This checkpoint fixes the R3E browser listen behavior where recognized text disappeared after the 5-second silence timer.

## Root cause

R3E rendered the Companion panel after stopping browser recognition. That replaced the textarea element and cleared the recognized text. In auto-send mode, the submit path then read the new empty textarea.

## Fix

- Preserve the recognized prompt text before stopping listening.
- Restore the prompt text after Companion render.
- Capture the auto-send text before render and submit that captured text if the new textarea is empty.

## Scope

- Repo mirror patch: `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- Repo mirror cachebust: `frontend/wrapper-ui/apc-wrapper-local/index.html`
- Live VM200 static patch only

No backend changes, no DB writes, no service restarts, no CT/VM restart, and no model/runtime/scheduler mutation.
