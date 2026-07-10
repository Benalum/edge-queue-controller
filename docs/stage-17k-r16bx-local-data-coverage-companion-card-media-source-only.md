# Stage 17K R16BX — Local data coverage, companion media, and card images

This stage is source-only.

## What changed

- Current/local backup payload generation is wrapped with a full local coverage helper.
- Backup coverage now includes Study decks, cards, sessions, progress, local events, localStorage fallback data, Profile settings, Companion settings, custom companion media references, and local media blob data URLs.
- Backup policy explicitly records Anki source files as read-only: Buddies Who Study may read Anki cards/decks, but writes only Buddies progress locally and never mutates Anki files.
- Profile gains local custom companion media inputs for listening, talking, and thinking clips.
- Study cards gain local front/question image and back/answer image support.
- Companion displays the active card image next to the companion name: front image while asking, back image while showing/checking the answer.
- Companion can resolve custom companion clips from local IndexedDB media storage.

## Why this was needed

The previous local backup panels could preview and download sanitized snapshots, but the active local-first app now has data in several browser-local places:

- APC_STUDY_STORE / localStorage fallback.
- APC_LOCAL_SAVE IndexedDB docs/events/media.
- Profile and Companion local settings.
- Card image and custom companion clip media blobs.

R16BX makes the backup payload pull those together before save/download/open-current-file workflows.

## Safety rails

- No VM deploy.
- No SSH.
- No sudo.
- No backend upload.
- No Google Drive sync activation.
- No Anki mutation.
- No original Anki/APKG/profile bytes are copied into backups.
