# Stage 5P-6C Study Session Mark Card Integration Smoke

Adds a live integration smoke for card-level Study session commands.

The smoke verifies:

- create smoke user/session
- create deck
- create two cards
- start study session through command endpoint
- read first answer
- mark first card correct
- verify session advances to second card
- read second answer
- mark second card incorrect
- verify session completes

This stage does not add runtime behavior. It only adds integration test coverage.
