# Stage 17K-K-R3 — Preserve Active Anki Memory Session

Date: 2026-06-28

## Summary

Stage 17K-K-R3 repairs an edge case found during live reveal/right/wrong proof.

Observed live state:

- cards were loaded in browser memory
- `active: true`
- `card_count_in_memory: 2`
- a later empty reload click changed status to `error`
- message became `No file selected.`

The repair preserves the active in-memory Anki session when the user clicks load again without a selected file but cards are already loaded.

## Behavior after repair

If cards are already loaded in JavaScript memory and the user clicks load with no file selected:

- keep status active when the session is active
- keep existing in-memory cards
- do not clear cards
- do not call backend
- show a helpful message to use reveal/right/wrong or stop and re-select the file

## Privacy

No card text is saved to localStorage.

No Anki content is uploaded.

No backend call is added.

No Anki write is added.

## Safety

This source repair does not deploy frontend code.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
