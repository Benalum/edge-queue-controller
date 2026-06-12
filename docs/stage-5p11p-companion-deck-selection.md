# Stage 5P-11P Companion Deck Selection

Adds Companion Study deck commands without adding new Companion buttons.

Supported phrases:

- List decks
- List my decks
- Show my decks
- What decks do I have?
- Select deck 2
- Select deck 10
- Select my math deck
- Use math deck
- Start math deck

Behavior:

- Deck listing fetches `/api/study/decks`.
- Deck selection stores the selected deck id in `localStorage.stage5p9aSelectedStudyDeckId`.
- Starting a named deck selects it and sends `Study session start` with `deck_id`.
- Existing Study session commands continue to work.
- True multi-deck sessions are deferred until the backend session queue supports multiple `deck_ids`.
