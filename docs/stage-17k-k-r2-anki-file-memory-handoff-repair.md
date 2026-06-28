# Stage 17K-K-R2 — Anki File Memory Handoff Repair

Date: 2026-06-28

## Summary

Stage 17K-K-R2 repairs the browser UI handoff for the Anki Basic memory session before live deploy.

The Stage 17K-K source panel re-renders after file selection. Browser file inputs lose their selected file when replaced by a re-rendered input.

This repair keeps the selected Anki file object in a module-level JavaScript memory variable only:

- `selectedAnkiFile`

The file object is used only to bridge the user action from file selection to local card extraction.

## Privacy

The selected file object is not saved to localStorage.

The selected file object is not uploaded.

The selected file object is cleared after extraction starts.

The selected file object is also cleared on stop and clear.

Anki card content remains JavaScript memory only.

No backend call is added.

## Safety

This source repair does not deploy frontend code.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
