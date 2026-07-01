# Stage 17K-Z-R12P-R2 — Local Card, Anki, and Companion Media Plan

## Status

Planning checkpoint only.

No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study doc write.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.

## Goal

Add media support to Buddies Who Study cards, read-only Anki cards, and Companion study sessions while preserving the privacy model:

- user card and media data stays browser-local
- Anki files remain read-only
- server does not receive private cards, notes, answers, Anki content, or media
- Companion can display the current card media locally while the learner is studying

## Current user-facing state

The signed-in Profile page has an acceptable layout.

Top row:

- Account
- Buddies Who Study local backups

Second row:

- Anki
- Google Drive sync

Known issue deferred:

- signed-out hard refresh /profile can briefly flash old Anki UI

## Core privacy boundaries

Must never happen by default:

- No original Anki file mutation.
- No collection.anki2 write.
- No Anki media folder write.
- No Anki card, note, or media upload to backend.
- No Buddies Who Study private card or media upload to backend.
- No Companion server-side storage of card text, answer text, or media.
- No backend private Study routes reintroduced.
- No Google Drive sync activation until explicitly approved later.

Allowed locally:

- Browser reads user-selected local files.
- Browser parses selected Anki/APKG files locally.
- Browser stores imported or converted copies in browser-local storage.
- Browser creates local object URLs for current-card media display.
- Browser exports/imports backups chosen by the user.

## Media model

Media item record fields:

- id
- sourceType: bws-local, anki-profile, or anki-apkg-import
- sourceId
- originalFilename
- safeFilename
- mimeType
- kind: image, audio, video, or unknown
- sizeBytes
- sha256
- createdAt
- updatedAt
- blobRef
- objectUrl as temporary runtime-only value
- ankiMediaName
- ankiMediaOrdinal
- status: available, missing, blocked, or unsupported

Card media reference fields:

- mediaId
- slot: front, back, hint, or explanation
- role: inline, attachment, or background
- alt
- caption
- sourceHtmlRef
- order

Proposed browser-local storage keys:

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

Existing local Study docs remain:

- study/cards/v1
- study/decks/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

## Buddies Who Study native card media

First version should start with images only.

Supported actions:

- attach image to a local card
- render image on card front/back
- remove media reference from local card
- keep media blob only in browser-local storage
- include media in backup/export
- restore media from backup/import

Do not add server upload.

Later versions can add:

- audio
- video
- captions
- alt text editor
- multiple media per side
- drag/reorder media
- image compression choice

## Anki media support

Direct Anki profile or collection file:

- user selects Anki folder or collection.anki2
- browser reads SQLite locally with sql.js
- browser reads media files only if browser selection grants access
- HTML fields are parsed locally
- image references and other media references are resolved against Anki media names
- missing media is marked as missing
- unsupported media is marked as unsupported
- original Anki files remain unchanged

First direct-file milestone:

- deck names
- card counts
- media reference names detected from field HTML
- no media extraction/write

APKG import/preview:

- browser opens ZIP locally
- browser locates collection.anki2 or collection.anki21
- browser reads APKG media mapping JSON
- numeric files like 0, 1, 2 map back to original filenames
- fields referencing filenames resolve to mapped files
- converted media is stored in Buddies Who Study browser-local import storage
- original APKG remains unchanged

First APKG media milestone:

- APKG media manifest parsed
- media filenames listed
- card HTML references mapped to media filenames
- no Study write until user explicitly imports/converts

## HTML and safety rules

Card HTML from Anki must be sanitized before display.

Allowed early tags:

- div
- span
- p
- br
- b
- strong
- i
- em
- u
- ul
- ol
- li
- table
- thead
- tbody
- tr
- td
- th
- img
- audio later

Blocked:

- script
- event handlers like onclick
- remote URLs by default
- iframes
- external tracking pixels
- inline JavaScript URLs
- untrusted CSS that can escape layout

Media URLs for display should be browser-created object URLs, not remote URLs.

## Companion media bridge

Companion should receive a local current-card view from the Study session layer.

Proposed current-card view shape:

- sourceType: bws-local or anki
- deckId
- deckName
- cardId
- frontHtml as sanitized HTML
- backHtml as sanitized HTML
- media list
  - mediaId
  - kind
  - mimeType
  - objectUrl as browser-runtime-only blob URL
  - alt
  - caption
  - slot
  - order
- privacy flags
  - serverUpload false
  - sourceMutation false
  - localOnly true

Companion may:

- show the current question
- show the current card media
- listen to user answer
- reveal answer
- show answer media
- mark right/wrong locally

Companion must not:

- upload card text
- upload media
- upload answer text
- mutate Anki files
- mutate Anki scheduling
- store private card/media content in backend DB

## Backup/export/import

The local backup format must include media.

Proposed backup structure:

- manifest.json
- study/decks.json
- study/cards.json
- study/progress.json
- study/sessions.json
- study/store-state.json
- study/card-media-refs.json
- study/media-manifest.json
- media files by sha256 or media id
- anki/imports.json
- anki/media-manifest.json

For single-file fallback download, use a JSON container first.

Larger media bundles can later use ZIP.

Backup manifest must include:

- backup kind
- version
- created time
- source browser label if available
- list of docs
- media count
- total media bytes
- sha256 per media item
- privacy flags
  - server upload false
  - Anki source mutation false
  - original Anki bytes included false unless explicitly exporting an imported copy

Restore/import must validate:

- backup kind
- version
- required docs
- media hashes
- size limits
- schema compatibility

Restore must never overwrite local data without explicit confirmation.

## Implementation milestones

R12Q — local backup schema plan and smoke

- backup manifest
- media manifest
- restore validation rules

R12R — native card media source skeleton

- disabled browser-local media vault helpers
- no UI mount
- no server calls
- no writes unless explicitly called
- image-only metadata helpers

R12S — local backup export includes media manifest

- extend backup builder to include empty media docs first

R12T — backup import/restore preview

- parse backup file
- validate
- show summary
- no write yet

R12U — native card image attachment UI

- add card image attachment for Buddies Who Study local cards

R12V — Anki SQLite read-only deck/card/media-reference proof

- parse selected Anki collection locally
- deck names
- card counts
- field HTML media reference names
- no write

R12W — APKG media manifest proof

- parse APKG media mapping
- list numeric media files
- map to filenames
- no write

R12X — Anki card preview with media

- render selected Anki card front/back with locally resolved images

R12Y — Companion current-card media bridge

- Companion displays current Study card media

R12Z — local-only Anki/Companion study flow

- show card with media
- answer
- reveal
- local right/wrong
- local aggregate stats only

## Recommended next code step

Start with R12Q as a narrow schema/source checkpoint for backup and media manifests.

Do not start by parsing Anki media yet. Backup/export/import must be safe before storing large media objects.
