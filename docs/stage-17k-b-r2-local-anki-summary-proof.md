# Stage 17K-B-R2 — Local Anki Summary Proof

Date: 2026-06-28

## Summary

Stage 17K-B-R2 successfully read the user's selected Anki collection with SQLite read-only mode and produced deck/card/note metadata without uploading or modifying the Anki file.

## Source

- Path: `/home/alex/.local/share/Anki2/User 1/collection.anki2`
- Header: `sqlite-anki-collection`
- Size: `139264` bytes
- Sample SHA-256: `3a186c5e1d133be32274d32cd73286de5d4dc59b95b40e8154590cce0e680805`

## Extracted summary

- Cards: `3`
- Notes: `3`
- Decks with cards: `2`
- Total deck IDs discovered: `2`
- Note types: `1`
- Tags: `3`

## Decks

- `Default`: 2 cards, 2 notes
- `Deck 1782669587926`: 1 card, 1 note

## Note types

- `Note Type 1782669512818`: 3 notes

## Tags

- `tags1`: 1
- `tags2`: 1
- `tags3`: 1

## Parse warnings

The collection's `col.decks` and `col.models` values were empty, so the tool used fallback names from `cards.did` and `notes.mid`.

This means card/note counts are usable, but a follow-up read-only schema diagnostic is needed to find the current source for deck and note type names.

## Safety proof

- SQLite open mode: `mode=ro`
- Writes performed: `false`
- Uploads performed: `false`
- Anki file modified: `false`

No frontend deploy, backend deploy, DB write, Anki write, full-file storage, model call, worker activation, scheduler activation, or service restart was performed.
