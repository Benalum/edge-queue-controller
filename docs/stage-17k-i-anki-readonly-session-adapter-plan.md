# Stage 17K-I — Anki Read-only Session Adapter Plan

Date: 2026-06-28

## Summary

Stage 17K-I defines the browser-local Anki read-only session adapter plan.

This is the bridge between:

- Stage 17K-F browser-local Anki deck extraction
- Stage 17K-H Study source selector
- a future real Study Session with Anki flow

The adapter must let a user study cards from a selected Anki deck without routing Anki data through the existing editable/backend-backed MyDecks study store.

## Current proven pieces

### Browser-local Anki summary

The Profile Anki picker can parse `collection.anki2` locally in the browser using same-origin vendored sql.js.

It has already proven:

- deck names
- card counts
- note counts
- note type summary
- no CDN use
- no server upload
- no Anki write

### Study source selection

The Study page can now select:

- `anki_browser_local`
- `mydecks_apc_native`

The Anki selection records a browser-local choice with:

- read-only permission
- no edit permission
- no create permission
- no delete permission
- no flag permission
- no Anki write permission
- no Anki content upload permission

## Key privacy constraint

The browser-local deck summary may be stored in localStorage.

Anki card content must not be stored in localStorage.

Anki card content includes:

- front text
- back text
- answer text
- tags
- media filenames
- media data
- note IDs
- card IDs
- per-card review history

## Important browser limitation

The browser cannot safely retain the full user-selected Anki SQLite file across a page reload using normal file input APIs.

Therefore, a real Anki study session must do one of these:

1. Reuse an in-memory file object if the user selected the file during the current page session.
2. Ask the user to select the Anki file again before starting the Anki study session.
3. Later, optionally use the File System Access API where supported, after a separate privacy/design approval.

For the first implementation, use option 2 as the reliable baseline:

- selected deck summary can remain in localStorage
- actual card extraction requires selecting the Anki file again
- card text is kept in memory only

## Adapter boundary

The future adapter should expose a new browser API, separate from `APC_STUDY_STORE`.

Recommended name:

- `window.APC_ANKI_READONLY_SESSION`

Recommended responsibilities:

- read the selected Anki source from `apc.study.sourceSelection.v1`
- verify `source_type === anki_browser_local`
- request or receive a user-selected Anki SQLite file
- parse cards for the selected deck locally with sql.js
- build an in-memory session deck
- expose next-card/current-card/answer/stop helpers
- keep all card content in memory only
- clear card content when the session stops or the page reloads

## Required non-goals

The adapter must not:

- call `/api/study/*`
- call any backend endpoint
- use `fetch`, `XMLHttpRequest`, or `sendBeacon`
- upload Anki card content
- upload Anki deck names
- upload Anki tags
- upload Anki media
- write to Anki
- update Anki scheduling
- insert Anki revlog rows
- edit cards
- create cards
- delete cards
- flag cards
- suspend cards
- bury cards
- route Anki cards into MyDecks automatically
- save Anki card text to localStorage

## Initial supported Anki card extraction

For the first adapter implementation, support the proven local schema shape:

- `cards`
- `notes`
- `fields`
- `notetypes`
- `templates`
- `decks`

Initial card extraction should:

- filter `cards.did` by selected Anki deck ID
- join cards to notes using `cards.nid = notes.id`
- split `notes.flds` on the Anki field separator `\x1f`
- use field names from `fields` table when available
- support Basic-style cards first
- map `Front` to question
- map `Back` to answer
- preserve only in-memory card objects for the active session

## Later Anki support

Later stages can add support for:

- cloze note rendering
- image/audio media lookup from local Anki media folders
- template-based front/back rendering
- filtered decks
- suspended/buried card filtering
- due card filtering
- learning/review/new queues
- local right/wrong session scoring
- aggregate-only server metrics

Each of these should remain local-only unless separately approved.

## Initial Study UI flow

The first real Anki Study UI should show:

1. selected source: Study with Anki
2. selected local deck name from source selector
3. a file chooser to re-select `collection.anki2`
4. a Start local Anki session button
5. current card question
6. answer reveal
7. right/wrong buttons
8. reviewed count
9. stop session button

The UI should clearly say:

- Anki card content stays in this browser session only.
- APC does not upload Anki card text, answers, tags, or media.
- This does not change the Anki file.

## Companion boundary

Companion may read from the Anki read-only session adapter only after a local Anki session is active.

For Anki sessions, Companion may:

- read the current question from memory
- listen to the user's answer
- compare the user's answer locally or by local-only logic for the MVP
- mark right/wrong locally
- advance to the next local card

For Anki sessions, Companion must not:

- create/edit/delete/flag Anki cards
- call MyDecks writeback actions
- send Anki card text to the backend
- send Anki card text to model jobs without separate local-model/privacy approval

## Future aggregate metrics

A later backend-approved stage may send aggregate-only metrics:

- source type: `anki_browser_local`
- session completed marker
- session length seconds
- cards reviewed count

It must not send:

- Anki deck name
- Anki deck ID
- Anki note ID
- Anki card ID
- Anki card text
- Anki answer text
- Anki tags
- Anki media names
- Anki media data
- per-card review history
- user spoken answer/transcript

## Recommended implementation order

1. Record this adapter plan.
2. Add frontend-only adapter skeleton with no card extraction.
3. Add local file re-select and selected-deck validation.
4. Add read-only Basic card extraction into memory.
5. Add local-only Study UI for question/reveal/right/wrong/stop.
6. Add Companion read-only current-card integration.
7. Add aggregate-only metrics later under separate backend approval.

## Safety

This checkpoint is documentation only.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
