# Stage 16 Study CRUD Writeback Live Hotfix Preservation R2

This checkpoint preserves live CT203 and VM200 Study/Companion hotfixes into repo source.

## Why R2 exists

The repo has `edge_controller.py` at repo root, but the live VM200 static site now uses a split-file webroot at:

`/var/www/apc-wrapper-local`

The repo did not have matching tracked files for:

- `privatepages/study-store.js`
- `privatepages/study.js`
- `privatepages/companion.js`
- `privatepages/sol.css`
- `privatepages/study-session.css`

So this checkpoint adds a live mirror at:

`frontend/wrapper-ui/apc-wrapper-local`

## Preserved live backend behavior

Backend source preserved from CT203:

`/opt/edge-queue-controller/current/edge_controller.py`

Key routes preserved:

- `/api/study/cards-lite`
- `/api/study/review-summary-lite`
- `/api/study/sessions-lite`
- `/api/study/session-writeback-lite`
- `/api/study/deck-writeback-lite`
- `/api/study/card-writeback-lite`

## Preserved live frontend behavior

Frontend source preserved from VM200:

`/var/www/apc-wrapper-local`

Key behavior preserved:

- Study syncs decks/cards/progress/review summary/sessions from CT203.
- Study deck create/edit persists to CT203.
- Study card create/edit/flag persists to CT203.
- Study delete/archive uses backend `archived_at`.
- Study sessions/reviews write back to CT203.
- Companion uses Study store functions for study session control.
- Companion study GUI is hidden/removed from the Companion surface.

## Live proof completed before preservation

- Card 24 `5+5` was edited through visible Study UI and persisted to CT203.
- Card 24 was changed back to answer `10`.
- Deck 38 was created through visible Study UI and persisted to CT203.
- Card 68 was created under deck 38 and persisted to CT203.
- Deck 38 was deleted through visible Study UI and archived with `archived_at`.
- Card 68 was archived with deck 38.
- Browser refresh proof showed archived deck/card disappeared and active decks/cards remained.

## Current active Study data at proof

Active decks:

- 37 `Dog names`
- 10 `mathmatic`

Active cards:

- 67 `Old dog` -> `Dougie`
- 66 `Lil dog` -> `Sol`
- 24 `5+5` -> `10`
- 23 `2+2` -> `4`
- 22 `2 + 3` -> `5`
- 21 `1 + 1` -> `2`
