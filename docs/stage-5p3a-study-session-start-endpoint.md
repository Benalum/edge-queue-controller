# Stage 5P-3A Study Session Start Endpoint

Adds the first lifecycle command for durable Study sessions:

- `POST /api/study/session/start`
- `POST /public/study/session/start`

This stage only starts a session. It does not add pause, resume, stop, command routing, model routing, queue lanes, or UI wiring.

Starting a session:

- requires `deck_id`
- verifies the deck belongs to the current user
- builds a card queue from active cards in that deck
- auto-stops any previous active session for that user
- creates a new `active` session
