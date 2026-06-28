# Stage 17K-G — Study Source Selector Plan

Date: 2026-06-28

## Summary

Stage 17K-G records the Study and Companion source selector plan after browser-local Anki deck extraction was proven live.

The Study flow should let users choose between:

1. Study with Anki
2. Study with MyDecks

## Source choices

### Study with Anki

Anki is a browser-local, read-only source.

The browser may:

- load the user-selected Anki file
- parse deck names locally
- let the user select a deck
- show cards locally
- listen for answers
- mark right/wrong locally during the active session
- show local card media when available

The browser must not:

- upload Anki deck names
- upload Anki card text
- upload Anki answers
- upload Anki tags
- upload Anki media
- write to Anki
- edit Anki cards
- create Anki cards
- delete Anki cards
- flag Anki cards
- suspend Anki cards
- bury Anki cards
- save per-card Anki history server-side

Initial server metrics allowed for Anki are aggregate-only:

- source type: anki_browser_local
- session completed marker
- session length in seconds
- cards reviewed count

### Study with MyDecks

MyDecks is the APC-native deck source.

MyDecks may eventually support:

- user-created cards
- AI-generated cards
- imports from Anki
- editing
- deleting or archiving
- saved study history
- Google Drive sync
- subscription-backed deeper analytics

MyDecks permissions must remain separate from Anki permissions.

## Companion behavior

Companion should become source-aware.

When a user starts a study session, Companion should know:

- selected source: Anki or MyDecks
- selected deck source ID
- whether edits are allowed
- whether server persistence is allowed
- whether card content is local-only

For Anki sessions, Companion must operate in read-only/local-only mode.

For MyDecks sessions, Companion can use APC-native deck permissions.

## Initial UI direction

Study entry should show two clear actions:

- Start Study Session with Anki
- Start Study Session with MyDecks

The Anki action should depend on a browser-local Anki file summary already available from the Profile Anki picker.

The MyDecks action can initially show a placeholder until APC-native decks are implemented.

## Admin metrics direction

The admin page should initially track only aggregate counters:

- total study sessions
- total Anki sessions
- total MyDecks sessions
- total session time
- total cards reviewed

The admin page must not show private Anki deck names, card text, answers, tags, or media.

## Recommended implementation order

1. Add source selector plan and smoke.
2. Add a small frontend-only Study source selector UI.
3. Connect Anki source selector to the browser-local summary.
4. Add local Anki deck selection to session start.
5. Add aggregate-only session completion event later, with separate backend approval.
6. Add MyDecks model/schema later, with separate DB approval.
7. Add Google Drive sync later, with separate OAuth/Drive approval.

## Safety

This checkpoint is documentation only.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
