# GoogleSync

Stage: 17K-Z-R4
Status: local schemas and validators only

This folder contains the isolated Google Drive sync contract artifacts for AI Platform Control.

Safety boundary:

- No OAuth activation.
- No Google Drive reads.
- No Google Drive writes.
- No backend deploy.
- No frontend deploy.
- No database writes.
- No model calls.
- No worker activation.
- No scheduler activation.
- No service restarts.

Folder policy:

- Keep Drive sync schemas in GoogleSync/schemas.
- Keep local validator code in GoogleSync/validators.
- Keep local fixtures in GoogleSync/fixtures.
- Do not scatter Drive sync implementation files across the repo without a separate approved refactor.

Current schema files:

- manifest.schema.json.
- deck.schema.json.
- card.schema.json.
- session.schema.json.
- user_stats.schema.json.
- deck_stats.schema.json.
- history_event.schema.json.
- conflict.schema.json.
- outbox_entry.schema.json.
- consent_event.schema.json.

Validator:

- GoogleSync/validators/validate_google_sync_schemas.py validates schema structure and local fixtures.
- The validator is dependency-free and uses only the Python standard library.
- The validator does not call Google APIs.
- The validator does not activate OAuth.
- The validator does not write to Drive.

## Stage 17K-Z-R5

R5 adds the browser-local IndexedDB outbox contract.

R5 files:

- GoogleSync/contracts/stage-17k-z-r5-indexeddb-outbox-contract.md.
- GoogleSync/contracts/indexeddb-outbox-contract.apc.json.
- GoogleSync/fixtures/valid/indexeddb_outbox_entry.r5.valid.json.
- GoogleSync/validators/validate_indexeddb_outbox_contract.py.

R5 remains contract-only:

- No OAuth activation.
- No Drive writes.
- No frontend runtime implementation.
- No backend runtime implementation.

## Stage 17K-Z-R6

R6 adds a Profile-only Google Drive sync/login UI shell.

R6 remains source-only:

- Profile page runtime only.
- Shared privatepages router source is allowed only with a Profile runtime guard.
- No OAuth activation.
- No Drive reads.
- No Drive writes.
- No backend deploy.
- No frontend deploy.

R6 files:

- GoogleSync/contracts/stage-17k-z-r6-profile-only-google-sync-login-ui.md.
- GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt.
- The selected source file recorded in the source path contract.

## Stage 17K-Z-R6B

R6B verifies the Profile-only GoogleSync UI shell source placement.

R6B remains verification-only:

- No source relocation.
- No OAuth activation.
- No Drive reads.
- No Drive writes.
- No backend deploy.
- No frontend deploy.

R6B recommendation:

- Keep the current guarded placement only temporarily if it is Profile-adjacent.
- Before real OAuth activation, split the GoogleSync UI into a clearer Profile-specific module.

## Stage 17K-Z-R6C

R6C splits the Profile-only GoogleSync UI shell into a cleaner Profile GoogleSync module.

R6C remains source-only:

- No OAuth activation.
- No Drive reads.
- No Drive writes.
- No backend deploy.
- No frontend deploy.

R6C library decision:

- Use Google Identity Services JavaScript authorization for future OAuth.
- Use the Google Drive REST API for future Drive operations.
- Use Google Picker for future user-selected files and folders.
- Do not build custom OAuth.

## Stage 17K-Z-R7

R7 adds Profile-only Google OAuth and Drive dev proof source.

R7 behavior:

- Uses Google Identity Services in the browser.
- Uses narrow drive.file access.
- Requires explicit Profile-page consent.
- Creates one harmless APC test file only after consent.
- Reads that test file metadata.
- Deletes that test file during rollback.
- Keeps access token in memory only.
- Does not use backend queue or backend DB.

PPB smoke remains static and does not call Google.
