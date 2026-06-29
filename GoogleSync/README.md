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
