# Stage 17K-U-R2 — Companion Anki Consented Study Handoff Plan Repair

Date: 2026-06-28

## Summary

Stage 17K-U-R2 repairs the Stage 17K-U plan documentation after the first plan file was accidentally written as a single-line escaped-newline file.

Stage 17K-T proved that Companion can mount the read-only Anki controls, load a selected local Anki deck into browser memory, and report active session shape only.

Stage 17K-U-R2 keeps the default path shape-only and requires explicit user consent before any current Anki card text can be used by a study interaction.

## Current proven state

- Companion can mount the local Anki read-only session controls.
- The user can re-select a local Anki file in the browser.
- The user can load a selected Anki deck into JavaScript memory only.
- Companion can report active session status and current card shape.
- The bridge does not return question text by default.
- The bridge does not return answer text by default.
- Backend calls remain disallowed.
- Model calls remain disallowed.
- Anki writes remain disallowed.
- MyDecks writeback remains disallowed for Anki-sourced cards.

## Design goal

Add a clearly named consent boundary for study handoff:

- default: Companion sees shape only
- user action: allow current card text for this local study interaction
- scope: current browser page/session only
- persistence: no Anki card text in localStorage
- backend: no backend handoff until separately approved
- model: no model handoff until separately approved
- Anki: no Anki writes
- MyDecks: no Anki-to-MyDecks writeback

## Proposed UI behavior

On Companion, after a deck is loaded:

1. Show current local Anki session status.
2. Show shape-only information by default.
3. Add a button such as `Use current Anki card in Companion study`.
4. Button text must explain that this shares the current card with the local Companion study interaction.
5. The command should return a consented payload only after the user clicks the button.
6. The command should include question and answer text only in the immediate browser result, not in docs, localStorage, or backend.

## Proposed API shape

New bridge command candidate:

- `consentedCurrentAnkiCardForStudyCommand()`

Default command behavior:

- returns `consented: false`
- returns shape only
- does not include `question`
- does not include `answer`

After user action:

- returns `consented: true`
- returns current card text for this browser interaction only
- includes privacy flags
- does not persist card text
- does not call backend
- does not call model
- does not write Anki

## Required proof for implementation

Pre-consent proof must show:

- `consented: false`
- no question text
- no answer text
- shape present
- no backend call
- no model call
- no Anki write

Post-consent proof must show:

- `consented: true`
- current card text available only in the immediate browser result
- no localStorage card text
- no backend call
- no model call
- no Anki write
- no MyDecks writeback

## Safety boundary

This stage is a plan repair only.

No source runtime behavior is changed by this repair.

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.

No Anki question text or answer text is saved to repo docs.
