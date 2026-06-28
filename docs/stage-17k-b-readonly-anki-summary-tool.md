# Stage 17K-B — Read-only Anki Collection Summary Tool

Date: 2026-06-28

## Summary

Stage 17K-B adds a local Python proof tool for reading collection.anki2 or collection.anki21 metadata before adding any browser SQLite/WASM dependency.

The tool extracts deck names, card counts, note counts, note type names, tag counts, SQLite header proof, and sample SHA-256 proof.

## Safety

The tool opens SQLite using URI mode=ro.

It does not write to Anki, upload the Anki file, save full file contents, modify the database, deploy frontend/backend code, run a model, or activate workers/schedulers.

## Example command

python3 ops/anki/anki_collection_readonly_summary.py --collection "$HOME/.local/share/Anki2/User 1/collection.anki2" --json-out /tmp/apc-anki-collection-summary.json
