# Stage 17K-E — Anki Local-only Study Contract

Date: 2026-06-28

## Summary

Stage 17K-E records the product and safety contract for using Anki decks inside APC Study and Companion.

Anki decks are a browser-local, read-only study source.

APC-native decks, currently called MyDecks as a working name, are the editable APC-owned deck source.

## Source selector

Companion and Study should expose a source choice before starting a study session:

1. Study with Anki
2. Study with MyDecks

## Anki source boundary

When the user chooses Study with Anki:

- The Anki file is selected by the user in the browser.
- The Anki file is parsed in the browser.
- Deck names are parsed locally.
- The user selects which Anki deck to study.
- Card/question/answer/media content remains local to the browser.
- APC does not upload Anki deck names, card text, answers, note fields, tags, or media to the server.
- APC does not write to the Anki collection.

## Allowed Anki session behavior

For Anki decks, Companion/Study may:

- list deck names locally
- let the user select a deck locally
- read/show the question/front locally
- listen for the user's answer
- show the answer/back locally
- show local images/media included in the card when available
- mark the card right or wrong locally
- advance through the selected deck
- keep local in-session progress while the browser session is active

## Forbidden Anki session behavior

For Anki decks, Companion/Study must not:

- edit Anki cards
- create Anki cards
- delete Anki cards
- flag Anki cards
- suspend Anki cards
- bury Anki cards
- create Anki decks
- delete Anki decks
- rename Anki decks
- write to collection.anki2 or collection.anki21
- write to collection.media
- upload Anki card text
- upload Anki answers
- upload Anki deck names
- upload Anki note fields
- upload Anki tags
- upload Anki media
- save per-card Anki study history server-side

## Initial server-side metrics allowed

For now, APC may send only aggregate Anki session metrics to the server:

- source type: anki_browser_local
- session completed marker
- session length in seconds
- cards reviewed count

The server can use those aggregates to maintain admin totals:

- total Anki sessions
- total Anki session time
- total Anki cards reviewed

## Initial server-side metrics not allowed

For now, APC must not send or save:

- deck name
- deck ID
- card ID
- note ID
- note type name
- card question text
- card answer text
- field names
- tag names
- media filenames
- image data
- audio data
- per-card right/wrong history
- per-card timing
- per-card user answer text
- transcript of spoken answers

## Right/wrong handling

Right/wrong marking for Anki sessions is local-only in the initial version.

It may be used to guide the active browser session, but it must not be written to Anki or saved server-side until a later explicit subscription/privacy design is approved.

## MyDecks boundary

MyDecks is the working name for APC-native decks.

MyDecks may later support:

- creating cards
- editing cards
- deleting/archive cards
- AI-generated cards
- imported cards
- server-side progress
- Google Drive sync
- subscription-backed saved study history

MyDecks permissions must stay separate from Anki permissions.

Anki read-only limitations must not leak into MyDecks, and MyDecks edit permissions must not leak into Anki.

## Admin page direction

The admin page should eventually show aggregate totals only for the initial Anki implementation:

- total sessions
- total session time
- total cards reviewed

These totals should not expose private Anki content.

## Future paid subscription direction

Later, paid subscriptions may enable saving more study data.

That future design requires a separate explicit approval and privacy contract before implementation.

## Safety boundaries

This checkpoint is documentation only.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
