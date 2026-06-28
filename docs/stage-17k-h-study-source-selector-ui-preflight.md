# Stage 17K-H — Study Source Selector UI Preflight

Date: 2026-06-28

## Summary

Stage 17K-H preflight identifies the safest frontend target for adding a Study source selector after Stage 17K-G.

The planned selector will expose:

- Study with Anki
- Study with MyDecks

## Required product boundary

Anki remains browser-local and read-only.

MyDecks remains the APC-native deck source.

The UI must keep the two permission models separate.

## Preflight goal

Before patching source, inspect:

- wrapper frontend files
- private page fragments
- Study references
- Companion references
- Anki/Profile panel references
- private page route loader references

## Expected next implementation

The next source patch should add a frontend-only Study source selector UI.

It should not send Anki content to the server.

It should not start a backend job, model call, worker, scheduler, DB write, Anki write, Google Drive write, or deploy by itself.

## Safety

This checkpoint is documentation and inventory only.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
