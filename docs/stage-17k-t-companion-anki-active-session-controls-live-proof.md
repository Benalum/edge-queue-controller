# Stage 17K-T — Companion Anki Active Session Controls Live Proof

Date: 2026-06-28

Stage 17K-T live proof passed.

- Source commit: `f0e23fe`
- Source tag: `controller-stage-17k-t-companion-anki-active-session-controls-2026-06-28`
- VM200 backup: `/home/jkg76nid/apc-vm200-frontend-backups/stage17kt-companion-anki-active-session-controls-20260629T033227Z`

Live markers:
- Bridge: `stage17ks-r2-companion-local-anki-session-mount-output-repair-20260628`
- Anki adapter: `stage17kt-companion-anki-active-session-controls-20260628`

Pre-load browser proof:
- `ok: true`
- `adapterHasRenderPanel: true`
- `mounted: true`
- `controlsVisible: true`
- `fileInputVisible: true`
- `hasRevealButton: true`
- `hasRightButton: true`
- `hasWrongButton: true`
- `hasStopButton: true`
- `doesNotReturnQuestionText: true`
- `doesNotReturnAnswerText: true`
- `noBackendAllowed: true`
- `noModelAllowed: true`
- `noAnkiWriteAllowed: true`

Post-load shape-only proof:
- `command: current_anki_card_shape`
- `sessionStatus: active`
- `active: true`
- `selectedDeckName: Anki Deck1`
- `cardCountInMemory: 2`
- `currentIndex: 0`
- `shape.present: true`
- `shape.has_question: true`
- `shape.has_answer: true`
- `shape.note_type_name: Basic`
- `doesNotReturnQuestionText: true`
- `doesNotReturnAnswerText: true`
- `noBackendAllowed: true`
- `noModelAllowed: true`
- `noAnkiWriteAllowed: true`

The Companion page can now mount the read-only Anki session controls, let the user load a selected local Anki deck into browser memory, and report only active session shape.

No Anki question text or answer text was saved to repo docs.

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.
