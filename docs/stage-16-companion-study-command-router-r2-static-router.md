# Stage 16 Companion Study Command Router R2 Static Router

This checkpoint adds a deterministic Study command router to Companion.

The command router works while idle, active, or paused. Users do not need to already be in a study session to list decks, select decks, list cards, create cards, edit cards, delete cards, flag cards, or start a study session.

## Commands added

- `list decks`
- `list cards`
- `select deck <name>`
- `show current card`
- `start study`
- `start hard study`
- `start new study`
- `start all study`
- `pause study`
- `resume study`
- `stop study`
- `create deck`
- `create card`
- `edit card`
- `delete card`
- `flag card`
- `unflag card`

## Multi-turn flows added

- Create deck: ask title, then description.
- Create card: ask deck, question, answer, then create as `new`.
- Edit card: identify card, ask field, ask value.
- Delete card: identify card, repeat question/answer, require exact `delete` confirmation.

## Durability

The router calls `window.APC_STUDY_STORE`, which already writes Study deck/card/session/review changes to CT203.
