# Stage 5P-11B Study Start Button Using Selected Deck

Adds a real Start button to the Study page.

Behavior:

- User loads decks.
- User selects a deck.
- Selected deck id is read from stage5p9aSelectedStudyDeckId.
- Start calls POST /api/study/session/start with { deck_id }.
- Study status card refreshes after start.

This stage does not add Companion testing tools.
This stage does not add voice.
This stage does not change Study command parsing.
