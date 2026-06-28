# Stage 17K-L — Anki Local Reveal / Right / Wrong / Stop Live Proof

Date: 2026-06-28

## Summary

Stage 17K-L successfully proved the browser-local Anki review loop on the live Study page.

Working user flow:

1. Re-select local `collection.anki2` through the browser file picker.
2. Select `Anki Deck1`.
3. Click `Load selected Anki deck into memory`.
4. Reveal answer locally.
5. Mark first card right locally.
6. Reveal second answer locally.
7. Mark second card wrong locally.
8. Stop the session and clear in-memory cards.

This proof intentionally does not record Anki question text or answer text.

## Source checkpoints

- Stage 17K-K source commit: `2c822f9`
- Stage 17K-K-R2 repair commit: `aa8831c`
- Stage 17K-K-R3 repair commit: `5f9b449`
- Stage 17K-K-R4 active status repair commit: `29b9d71`

## Deployed live marker

- `stage17kk-anki-basic-memory-session-20260628-r4-status-repair`

## VM200 backup

- `/home/jkg76nid/apc-vm200-frontend-backups/stage17kk-r4-anki-active-status-repair-20260628T223627Z`

## Browser proof

Browser console proof on `/study` returned:

- `ok: true`
- `apiVersion: stage17kk-anki-basic-memory-session-20260628`
- `before.status: active`
- `before.active: true`
- `before.cardCount: 2`
- `before.reviewed: 0`
- `before.correct: 0`
- `before.wrong: 0`
- `firstCardShape.hasQuestion: true`
- `firstCardShape.hasAnswer: true`
- `firstCardShape.deckName: Anki Deck1`
- `firstCardShape.noteTypeName: Basic`
- `afterReveal1.answerVisible: true`
- `afterReveal1.reviewed: 0`
- `afterRight1.status: active`
- `afterRight1.active: true`
- `afterRight1.reviewed: 1`
- `afterRight1.correct: 1`
- `afterRight1.wrong: 0`
- `secondCardShape.hasQuestion: true`
- `secondCardShape.hasAnswer: true`
- `secondCardShape.deckName: Anki Deck1`
- `secondCardShape.noteTypeName: Basic`
- `afterReveal2.answerVisible: true`
- `afterReveal2.reviewed: 1`
- `afterWrong2.status: complete`
- `afterWrong2.active: false`
- `afterWrong2.reviewed: 2`
- `afterWrong2.correct: 1`
- `afterWrong2.wrong: 1`
- `afterStop.status: stopped`
- `afterStop.active: false`
- `afterStop.reviewed: 2`
- `afterStop.correct: 1`
- `afterStop.wrong: 1`

## Privacy boundary

The Anki file is selected through the browser file picker and read locally in the browser.

No Anki file is uploaded to the server.

No Anki card text is saved to repo docs.

No Anki card text is intentionally saved to localStorage.

The adapter privacy flags remain:

- `browser_memory_only: true`
- `card_text_localstorage_allowed: false`
- `backend_calls_allowed: false`
- `anki_write_allowed: false`
- `mydecks_writeback_allowed: false`

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.

The live proof used already-deployed static frontend files only.

The stop action cleared in-memory cards.
