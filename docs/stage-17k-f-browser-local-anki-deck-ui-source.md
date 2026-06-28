# Stage 17K-F — Browser-local Anki Deck UI Source Patch

Date: 2026-06-28

## Summary

Stage 17K-F adds source support for browser-local Anki deck extraction in the Profile Anki panel.

The Profile Anki panel can now use the vendored same-origin sql.js assets to parse a user-selected collection.anki2 or collection.anki21 file locally in the browser.

## Browser-local behavior

The panel can locally extract:

- deck names
- deck IDs
- card counts by deck
- note counts by deck
- note type names
- note type fields
- note type templates
- tag counts

## Privacy contract

The Anki file remains local to the browser.

The panel does not upload:

- deck names
- card text
- answers
- fields
- tags
- media
- per-card answers
- per-card right/wrong state

The initial Anki implementation remains read-only and local-only.

## Source implementation

The panel loads:

- /vendor/sqljs/sql-wasm.js
- /vendor/sqljs/sql-wasm.wasm

The parser prefers newer Anki schema tables:

- decks
- notetypes
- fields
- templates

It keeps fallback support for older col.decks and col.models metadata.

## Safety

This source patch does not deploy frontend code.

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
