# Stage 17K-B-R3 — Table-name Anki Summary Proof

Date: 2026-06-28

## Summary

Stage 17K-B-R3 successfully read the user's selected Anki collection using SQLite read-only mode and extracted real deck, note type, field, and template names from the newer Anki table-based schema.

## Source

- Path: /home/alex/.local/share/Anki2/User 1/collection.anki2
- Header: sqlite-anki-collection
- Sample SHA-256: 3a186c5e1d133be32274d32cd73286de5d4dc59b95b40e8154590cce0e680805

## Extracted summary

- Cards: 3
- Notes: 3
- Decks with cards: 2
- Total decks in collection: 2
- Note types with notes: 1
- Total note types in collection: 6
- Tags: 3

## Decks

- Anki Deck1: 2 cards, 2 notes
- Anki Deck2: 1 card, 1 note

## Active note type

- Basic: 3 notes
- Fields: Front, Back
- Template: Card 1

## Schema features

- Deck names source: decks table
- Note type names source: notetypes table
- Fields source: fields table
- Templates source: templates table

## Parse warnings

col.decks and col.models were empty. This is expected for this collection because the active names were available in the newer table-based schema.

## Safety proof

- SQLite open mode: mode=ro
- Writes performed: false
- Uploads performed: false
- Anki file modified: false

No frontend deploy, backend deploy, DB write, Anki write, full-file storage, model call, worker activation, scheduler activation, or service restart was performed.
