# Stage 17K-J — Anki Read-only Session Adapter Skeleton Source Patch

Date: 2026-06-28

## Summary

Stage 17K-J adds a frontend-only Anki read-only session adapter skeleton.

It introduces:

- `window.APC_ANKI_READONLY_SESSION`
- a Study page skeleton panel
- selected Anki source validation
- file re-select header inspection
- in-memory-only session state

## What it does

The skeleton can:

- read the browser-local Study source selection
- confirm `anki_browser_local`
- ask the user to re-select an Anki SQLite file
- inspect the file header locally
- start and stop a skeleton session
- report an in-memory-only snapshot

## What it does not do

The skeleton does not:

- extract card text
- store card text in localStorage
- call the backend
- call `/api/study/*`
- use MyDecks writeback
- write to Anki
- create, edit, delete, flag, suspend, or bury Anki cards
- upload Anki deck names, card text, tags, answers, media, or per-card history

## Safety

This source patch does not deploy frontend code.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
