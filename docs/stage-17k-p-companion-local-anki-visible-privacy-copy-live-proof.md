# Stage 17K-P — Companion Local Anki Visible Privacy Copy Live Proof

Date: 2026-06-28

## Summary

Stage 17K-P successfully proved the Companion local Anki bridge visible privacy copy live on the Companion page.

The Companion bridge panel now visibly includes the privacy line:

- `This bridge does not return card question text or answer text.`

This proof intentionally does not record Anki question text or answer text.

## Source checkpoint

- Commit: `d3c0fb4`
- Tag: `controller-stage-17k-p-companion-local-anki-visible-privacy-copy-2026-06-28`

## VM200 backup

- `/home/jkg76nid/apc-vm200-frontend-backups/stage17kp-companion-local-anki-visible-privacy-copy-20260628T225750Z`

## Live marker

- `stage17kp-companion-local-anki-visible-privacy-copy-20260628`

## Browser proof

Browser console proof on `/companion` returned:

- `ok: true`
- `bridgeVersion: stage17kp-companion-local-anki-visible-privacy-copy-20260628`
- `panelPresent: true`
- `panelTextHasLocalOnlyCopy: true`
- `panelTextHasPrivacyCopy: true`
- `state.bridge_ready: true`
- `state.anki_adapter_present: true`
- `state.source_type: anki_browser_local`
- `state.status: idle`
- `state.active: false`
- `doesNotReturnQuestionText: true`
- `doesNotReturnAnswerText: true`
- `noBackendAllowed: true`
- `noModelAllowed: true`
- `noAnkiWriteAllowed: true`

## Resource proof

The browser loaded:

- `/privatepages/anki-readonly-session.js?v=stage17kk-anki-basic-memory-session-20260628-r4-status-repair`
- `/privatepages/companion-local-anki-bridge.js?v=stage17kp-companion-local-anki-visible-privacy-copy-20260628`

## Privacy boundary

The Companion local Anki bridge returns only shape/status/counter information.

It does not return Anki question text.

It does not return Anki answer text.

It does not allow backend calls.

It does not allow model calls.

It does not allow Anki writes.

It does not allow MyDecks writeback for Anki-sourced cards.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed for this proof.

The proof used already-deployed static frontend files only.
