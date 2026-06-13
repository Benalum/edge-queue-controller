# Phase 11N Deterministic Study Continue Aliases

Phase 11N adds deterministic aliases for moving forward in a Study session.

## Goal

Make natural commands like `continue`, `go on`, `move on`, and `next question` behave like `next card` during active Study sessions.

## Findings from Phase 11M

Already wired before this phase:

- `next`
- `next card`

Missing before this phase:

- `continue`
- `go on`
- `move on`
- `next question`

## Runtime changes

Files changed:

- `frontend/wrapper-ui/app.js`
- `edge_controller.py`

Frontend command detector now recognizes:

- `next question`
- `continue`
- `continue card`
- `continue cards`
- `go on`
- `move on`

Backend deterministic intent parser now maps these active-session phrases to:

- `intent`: `study_next_card`
- `command`: `next_card`

For paused sessions, plain `continue` safely maps to resume instead of advancing the card.

## Non-goals

No model fallback is added.

Router rollout remains parked:

- no backend dry-run env
- no frontend router POST traffic
- no persistent rollout mutation routes
- no rollout mutation routes
