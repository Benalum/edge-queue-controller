# Stage 5P-9A Study Deck Selector

Adds a frontend-only read-only deck selector near the Study session status card.

Behavior:

- Fetches GET /api/study/decks.
- Displays available decks.
- Stores the selected deck id in localStorage as stage5p9aSelectedStudyDeckId.
- Does not start a session.
- Does not add backend behavior.
- Does not change Companion behavior.

This creates a reliable deck id source for a later Start button stage.
