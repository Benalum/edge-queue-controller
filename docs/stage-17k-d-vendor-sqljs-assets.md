# Stage 17K-D — Vendor sql.js Assets

Date: 2026-06-28

## Summary

Stage 17K-D vendors pinned sql.js browser SQLite assets for the future browser-local Anki metadata extraction proof.

Vendored assets are stored under:

frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/

Assets:

- sql-wasm.js
- sql-wasm.wasm
- LICENSE.sql-js
- VERSION.txt
- SHA256SUMS

## Package

- Package: sql.js
- Version: 1.12.0
- License: MIT

## Purpose

These assets will allow APC to parse a user-selected collection.anki2 or collection.anki21 file in the browser, without uploading it to the backend.

## Production dependency rule

APC should serve sql.js same-origin from the vendored path.

Do not use a CDN dependency for production.

## Safety

This checkpoint only vendors static frontend assets and documentation.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.
