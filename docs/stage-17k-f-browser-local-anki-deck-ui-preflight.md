# Stage 17K-F — Browser-local Anki Deck UI Preflight

Date: 2026-06-28

## Summary

Stage 17K-F preflight confirms that the repo is ready for browser-local Anki deck extraction UI work.

The next source patch should use the existing Profile Anki file picker and the vendored sql.js assets to parse deck names locally in the browser.

## Contract

Anki remains browser-local and read-only.

The browser may parse:

- deck names
- deck IDs
- local card counts
- local note counts
- local note type names
- local field/template names

The server must not receive:

- Anki deck names
- Anki card text
- Anki answers
- Anki tags
- Anki media
- per-card answers
- per-card right/wrong history

The only future server metric allowed for initial Anki sessions is aggregate session data:

- source type: anki_browser_local
- session completed marker
- session length in seconds
- cards reviewed count

## Required local assets

The preflight requires:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html
- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/sql-wasm.js
- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/sql-wasm.wasm
- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/SHA256SUMS

## Next patch target

Stage 17K-F should add browser-only extraction to the existing Anki panel:

1. Load sql.js from same-origin vendored assets.
2. Read the user-selected Anki SQLite file into browser memory.
3. Extract deck names from the newer decks table when available.
4. Extract note type/field/template names from notetypes, fields, and templates when available.
5. Keep fallback support for older col.decks and col.models.
6. Render local deck choices without uploading Anki content.
7. Store only local browser proof/summary in localStorage.

## Safety

This preflight is documentation and smoke only.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
