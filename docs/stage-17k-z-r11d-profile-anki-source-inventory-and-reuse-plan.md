# Stage 17K-Z-R11D — Profile Anki Source Inventory and Reuse Plan

## Status

Source-only inventory and reuse plan.

No deploy.
No UI activation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite parsing.
No media extraction.

## Why this stage exists

Earlier Stage 17 work added Profile-tab Anki affordances so a user could point Buddies Who Study at Anki-related data.

R11B and R11C then added a new disabled browser-local importer skeleton and APKG container inspector.

Before building more, this stage inventories the existing Profile Anki path so the next implementation can reuse what already exists instead of creating a competing import surface.

## Files inventoried

Primary Profile and Anki-related frontend files:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html
- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-save-store.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js
- frontend/wrapper-ui/apc-wrapper-local/index.html

## Questions this inventory answers

- Is Profile still the right place for selecting an Anki source?
- Is the old Profile Anki feature a manifest paste/display path only?
- Is there already a file input or browser File API path?
- Is the old path connected to study-source-selector or Companion?
- Can R11C inspectApkgFile be wired into the old Profile path safely?
- Are any forbidden private Study server persistence routes referenced?
- Are Google Drive or OAuth references present in the same area and should remain parked?

## Expected decision

Use the existing Profile Anki surface as the user-facing entry point if it is still present and not broken.

Keep R11C as the underlying local APKG inspector.

The next implementation should not create a second competing Anki import button elsewhere unless the Profile path is missing or abandoned.

## Recommended R11E if Profile path is present

Add a disabled Profile bridge helper:

- keep it source-only
- no deploy
- no automatic mount if index.html does not already load it
- no backend calls
- no APC_LOCAL_SAVE writes
- no IndexedDB writes
- no localStorage writes
- no Google Drive
- no OAuth
- no SQLite row parsing
- no media extraction

The helper should adapt a browser File-like object from the Profile Anki chooser to:

- APC_ANKI_IMPORT_LOCAL.describeFileSource
- APC_ANKI_IMPORT_LOCAL.inspectApkgFile

It should return a read-only preview:

- filename
- size
- APKG container yes/no
- collection.anki2 present yes/no
- collection.anki21 present yes/no
- media manifest present yes/no
- numeric media entries present yes/no
- warnings

## Recommended R11E if Profile path is missing

Do not deploy a new UI yet.

Add an unmounted Profile Anki import panel draft and fixture-only smoke, then choose a later deploy stage.

## Safety rule carried forward

Anki decks/cards and user private study data remain browser-local only.

Server must not store private decks, cards, notes, Anki content, media, or private progress.

Original Anki files must not be mutated.
