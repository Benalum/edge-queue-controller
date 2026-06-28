# Stage 17K-B-R3 — Table-name Read-only Anki Summary

Date: 2026-06-28

## Summary

Stage 17K-B-R3 updates the local read-only Anki summary tool to use newer Anki table-based schema names.

The tool now prefers:

- decks.name for deck names
- notetypes.name for note type names
- fields.name for field names
- templates.name for card template names

It keeps fallback support for older col.decks and col.models metadata.

## Safety

The tool still opens SQLite using URI mode=ro and does not write to Anki, upload the file, save full file contents, deploy frontend/backend code, run a model, or activate workers/schedulers.
