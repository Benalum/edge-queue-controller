# Stage 17K-S-R2 — Companion Local Anki Session Mount Output Repair

Date: 2026-06-28

## Summary

Stage 17K-S-R2 repairs the Companion local Anki session mount output area.

Stage 17K-S live proof showed the mount command was present and safe, but the output area was not reliably present:

- `panelHasMountOutput: false`

This repair adds a resilient `ensureMountOutput(panel)` helper so the mount output area exists after render and after direct command calls.

## Scope

Static frontend source only:

- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js`

## Privacy boundary

The repair does not return Anki question text.

The repair does not return Anki answer text.

The repair does not add backend calls.

The repair does not add model calls.

The repair does not add Anki writes.

The repair does not add MyDecks writeback for Anki cards.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
