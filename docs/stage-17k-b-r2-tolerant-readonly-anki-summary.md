# Stage 17K-B-R2 — Tolerant Read-only Anki Summary

Date: 2026-06-28

## Summary

Stage 17K-B-R2 makes the local Anki summary tool tolerant when Anki collection metadata fields such as decks or models are not parseable JSON.

The tool still opens SQLite using URI mode=ro and falls back to deck IDs from cards.did and note type IDs from notes.mid when deck/model names are unavailable.

## Safety

No Anki write, file upload, full-file storage, frontend deploy, backend deploy, DB migration, model call, worker activation, scheduler activation, or service restart is performed.
