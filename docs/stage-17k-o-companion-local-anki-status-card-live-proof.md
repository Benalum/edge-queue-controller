# Stage 17K-O — Companion Local Anki Status Card Live Proof

Date: 2026-06-28

## Summary

Stage 17K-O successfully proved the Companion-side local Anki bridge panel on the live Companion page.

The Companion page can load the local Anki bridge and render a Companion-side status card.

This proof intentionally does not record Anki question text or answer text.

## Source checkpoint

- Stage 17K-N source commit: `9cd94cd`
- Stage 17K-N source tag: `controller-stage-17k-n-companion-local-anki-bridge-source-2026-06-28`
- Stage 17K-N live proof commit: `3cd12e0`
- Stage 17K-N live proof tag: `controller-stage-17k-n-companion-local-anki-bridge-live-proof-2026-06-28`

## Browser proof

Browser console proof on `/companion` returned:

- `ok: true`
- `bridgeVersion: stage17kn-companion-local-anki-bridge-source-20260628`
- `panelPresent: true`
- `panelTextHasLocalOnlyCopy: true`
- `panelTextHasPrivacyCopy: false`
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
- `/privatepages/companion-local-anki-bridge.js?v=stage17kn-companion-local-anki-bridge-source-20260628`

## Notes

`state.status: idle` and `state.active: false` are acceptable on the Companion route because active Anki card memory can be route/page-session dependent.

`panelTextHasPrivacyCopy: false` is non-blocking because the bridge snapshot itself proved:

- no question text returned
- no answer text returned
- backend calls disallowed
- model calls disallowed
- Anki writes disallowed

## Privacy boundary

The Companion local Anki bridge returns only shape/status/counter information.

It does not return Anki question text.

It does not return Anki answer text.

It does not allow backend calls.

It does not allow model calls.

It does not allow Anki writes.

It does not allow MyDecks writeback for Anki-sourced cards.

## Safety

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed for this proof.

The proof used already-deployed static frontend files only.
